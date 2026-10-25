# dbt — mart Casumina trên Apache Doris

Biến bảng ERP thô do đối tác nạp (`raw_stage`) thành các bảng `dim_*` / `fact_*` mà SmartBI, What-If,
Dự đoán đọc (CSDL Doris `mart`, cụm prod 192.168.15.197).

```
ERP đối tác ──nạp──▶ raw_stage (của đối tác, chỉ đọc)
                         │  dbt: staging = CTE (chuẩn hoá mã, kiểu) — không sinh bảng
                         ▼
                     mart.dim_csm_* / mart.fact_csm_* / meta_csm_data_coverage (26 bảng) ──▶ SmartBI / What-If
```

Nhánh `main` là bản PostgreSQL cũ (đang chạy trên dev .179); nhánh này (`feat/doris`) là bản Doris.

## Chạy

```bash
scripts/dbt_doris.sh build                       # dựng + kiểm tra, ghi vào CSDL `mart`
scripts/dbt_doris.sh run -s fact_csm_sales       # một bảng
DBT_TARGET_DB=tmp_x scripts/dbt_doris.sh build   # ghi vào CSDL khác (thử nghiệm)
scripts/dbt_doris.sh build --vars '{csm_source_schema: tmp_src}'   # đọc nguồn khác raw_stage
```

- dbt chạy trong container `docker/Dockerfile` (dbt-core 1.12.6 + dbt-doris 1.0.0, ghim phiên bản).
- Tài khoản `dbt_runner` (vai trò `role_transform`: đọc `raw_stage`, ghi `raw`/`mart`/`ops`).
  Mật khẩu lấy từ `DORIS_PASSWORD` hoặc vault của `ansible-csm-data`; profile sinh vào `.dbt/` (gitignore).
- Mặc định đi qua container VPN `csm-vpn` (máy dev); chạy trong LAN đối tác: `DBT_NETWORK=host`.
- Chạy định kỳ: `scripts/dbt_cron.sh` mỗi 20 phút trên máy DATA .197 (role `dbt` của `ansible-csm-data`):
  khoá chống chạy chồng, log `logs/dbt_YYYYMMDD.log`, tự dựng lại một lần nếu nguồn bị ghi chen ngang.
- Chống đọc dữ liệu dở dang: đối tác xoá + nạp lại tháng hiện tại khoảng 18 phút/lần ⇒ trước khi dựng, dbt chờ
  `raw_stage` không bị ghi ≥ 2 phút; sau khi dựng kiểm lại nguồn không đổi (`macros/csm_source_guard.sql`).
- Bảng cũ / bảng tạm của dbt xoá bằng `FORCE` (không dồn ~1.900 bảng/ngày vào thùng rác Doris).
- Một lần dựng toàn bộ ~30 giây (thử tải: ~12 triệu dòng / 24 năm 41 giây; ×60 khối lượng 73 giây); mỗi bảng dựng vào bảng tạm rồi hoán đổi nguyên tử —
  BI không bao giờ đọc bảng dở dang.

## Quy ước dữ liệu (đọc trước khi viết truy vấn BI)

| Chủ đề | Quy ước |
|---|---|
| Mã | Sản phẩm / vật tư / khách hàng: viết hoa, bỏ khoảng trắng (ERP lẫn `410khac00152`, `01030291 `). |
| Kỳ | `period_from`/`period_to` = đầu/cuối tháng; `period_date` = ngày đầu tháng, riêng `fact_csm_bom` = ngày CUỐI tháng. |
| Dấu giá thành | `fact_csm_product_cost`: chi phí ÂM như ERP, `qty` dương ⇒ hiển thị chi phí dùng `-SUM(...)`. What-If tự đổi dấu. |
| Khoản mục Z | 12 khoản theo `costing_title` của ERP: `nvlc vl_phu fuel packing ccpt dien_luc luong bhxh_yt kpcd khcb scl cppx`; tổng = `cost_total_components`. |
| Doanh thu | `fact_csm_sales.amount` (đã gồm dòng điều chỉnh âm) + `fact_csm_service_invoice.amount`. `doc_type` là mã ERP (0, 5 bán; 12 điều chỉnh), không phải inland/export. |
| Tồn kho / công nợ | Có đủ mọi tháng ⇒ `WHERE period_date = …` ra toàn bộ tồn / dư nợ của tháng đó. |
| Độ phủ dữ liệu | `meta_csm_data_coverage`: mỗi bảng fact có số từ kỳ nào tới kỳ nào, kỳ cuối đã đủ tháng chưa. Tháng hiện tại là số luỹ kế (đối tác nạp lại nhiều lần/ngày); giá thành, lãi gộp, BOM chỉ có khi tháng đã khoá sổ. |
| Lãi gộp | `fact_csm_product_profit` ERP ghi gần hết ở đơn vị 01 (Văn phòng) — không so lãi giữa xí nghiệp. |

Từ điển đầy đủ từng bảng / cột: `models/marts/csm/_csm__models.yml` — dbt ghi luôn vào COMMENT bảng/cột của
Doris (`persist_docs`), nên SmartBI / AI đọc được nghĩa cột ngay từ schema.

## Khác bản PostgreSQL cũ (sửa lỗi nghiệp vụ)

Tên bảng, tên cột cũ giữ nguyên (truy vấn cũ không lỗi). Những chỗ đổi số liệu:

1. **Khoản mục giá thành bị gán nhầm** (`fact_csm_product_cost`). Đối chiếu `costing_title`, tỷ lệ luật định
   (BHXH ≈ 15% lương, KPCĐ ≈ 1–2%) và ETL thứ hai: `Discount` là KHẤU HAO (bản cũ gọi `chiet_khau`),
   `CostWarehouse` là CHI PHÍ PHÂN XƯỞNG (bản cũ gọi `khcb`), `OtherMaterial` là CÔNG CỤ PHỤ TÙNG (bản cũ
   gọi `cppx`), `Party` là KPCĐ, `Repair` là SỬA CHỮA LỚN; `Warranty` (BHXH) bị đưa vào 2 cột. Nay mỗi khoản
   đúng tên, thêm `ccpt`; 5 cột cũ không phải khoản mục (`warranty party chiet_khau repair cost_warehouse`) = 0.
2. **Số lượng chứa số tiền**: dòng điều chỉnh hoá đơn (mã giả 2900xx, nhóm hàng 12, hoá đơn loại 12) ERP ghi
   tiền vào cột số lượng ⇒ `qty` bán 2024 bị phình 285 tỷ "cái", sản lượng tiêu thụ kế hoạch 425 tỷ.
   Nay không tính vào số lượng; `fact_csm_sales.is_adjustment` đánh dấu dòng điều chỉnh.
3. **Tồn kho luôn bằng 0** (`fact_csm_material`, `fact_csm_fg_inventory`, `fact_csm_production`): cột tồn của
   ERP rỗng. Nay tồn cuối = số chụp số dư gần nhất (dòng ngày 31/12) + luỹ kế nhập tổng − xuất tổng;
   thêm tồn đầu tháng và tổng nhập / xuất. Giá trị tồn THÀNH PHẨM là xấp xỉ (ERP đánh giá lại giá vốn).
4. **Công nợ chỉ có phát sinh**: thêm `balance_end` / `balance_end_lcy` (dư nợ cuối tháng).
5. **Mã lệch hoa / thường, khoảng trắng**: chuẩn hoá ⇒ nối được dim (prod: 231 mã giá thành trước đây "mồ côi").
6. **Nguồn chưa có** (`business_planning*`): ra bảng rỗng đúng cấu trúc thay vì làm hỏng cả lần chạy.
7. **Bỏ dữ liệu demo**: danh sách phòng ban tự đặt (`seed_department`) không phải dữ liệu ERP ⇒ `dim_csm_department`
   đọc bảng `department` của ERP (rỗng tới khi ERP có).

## Kiểm chứng (10/2026)

- **Tương đương**: nạp nguyên dữ liệu nguồn dev (2022–2024) vào Doris, dựng bằng bản này và so từng dòng với
  mart PG cũ trên cùng dữ liệu: 25/25 bảng khớp, chênh lệch chỉ đúng các mục sửa ở trên.
- **Nối kỳ dev → prod**: tồn / công nợ cuối 12/2024 tính từ dữ liệu dev = số đầu kỳ ERP trên prod:
  tồn NVL khớp từng xí nghiệp (trừ XN 02), 4.230/4.231 mã; tồn thành phẩm 1.729/1.729 mã;
  công nợ 353/353 khách (743,39 tỷ).
- **Test tự động** (`dbt build` chạy cùng): đẳng thức 12 khoản mục Z, tổng mart = tổng nguồn, đẳng thức tồn,
  dư nợ khớp nguồn, khoá không trùng, giả định về dòng chụp số dư của ERP.

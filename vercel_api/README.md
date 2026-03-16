# ChiTieuPlus AI Proxy (Vercel)

Đây là mã nguồn Backend Serverless dùng để ẩn API Key Gemini của ứng dụng ChiTieuPlus.

## Hướng dẫn Deploy lên Vercel miễn phí

1. Mở Github Desktop hoặc dùng lệnh Git để **Commit và Push** thư mục này (`vercel_api`) lên tài khoản GitHub của bạn (Push cả project `CHITIEU_PLUS` lên là được).
2. Đăng nhập vào [Vercel.com](https://vercel.com/) (Dùng tài khoản GitHub).
3. Nhấn **"Add New Project"**.
4. Import Repository chứa dự án ChiTieuPlus của bạn.
5. Tại phần cấu hình (Configure Project):
   - **Framework Preset**: Chọn `Other`.
   - **Root Directory**: Nhấn nút `Edit` và chọn thư mục `vercel_api`.
   - **Environment Variables**: Nhập thông tin sau:
     - Name: `GEMINI_API_KEY`
     - Value: *(Dán API Key Gemini của bạn vào đây)*
6. Nhấn **Deploy**.
7. Đợi 1 phút, Vercel sẽ cấp cho bạn một đường Link (Domain). Copy đường link đó và dán đè vào biến `_vercelProxyUrl` trong file `lib/services/ai_service.dart` của ứng dụng Flutter!

Ví dụ Domain thực tế: `https://chitieuplus-proxy.vercel.app/api/gemini`

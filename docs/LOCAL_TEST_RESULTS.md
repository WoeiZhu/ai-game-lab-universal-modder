# 本地 P0–P2 測試結果 — 2026-10-13

執行基準：初始化 commit `488ffc313408ff0c2983271204cf4ecabc9a022f`；盤點時修正 ffmpeg 的版本旗標為 `-version`。私人路徑、原始日志、環境報告、workflow 與圖片未提交。

| 階段 | 結果 | 實測證據 |
|---|---|---|
| P0 工具盤點 | PASS | Git 2.49.0、Python 3.12.9、uv 0.6.17、ffmpeg 8.0；Blender 5.2.1 可用但未在 PATH |
| P1 CLI 安裝 | PASS | 固定 upstream commit，專案專用 uv tool 環境；`um --version`／`um --help` 退出碼均為 0 |
| P1 環境保護比對 | PASS（限定取樣） | 7,168 個程式／設定／套件 metadata 檔案 SHA256 不變；244 個模型的大小／mtime 不變；ComfyUI／Python／Torch 版本不變 |
| P2a 連線 | PASS | loopback ComfyUI 0.37.0，僅 GET 狀態 |
| P2b 圖片 smoke test | PASS | 既有 SD1.5 checkpoint、標準本地節點；256×256、12 steps、seed 42；PNG 可解碼且目視可見置中的機器人 |
| H3／WanVideo 功能回歸 | NOT_RUN | 未執行原影片工作流；檔案不變不能證明功能回歸通過 |
| P3–P7 | NOT_RUN | 不擴大此次測試範圍 |

## CLI 來源與依賴

Universal Modder 0.2.0，upstream commit `5ba8150e27b4f1bf17ae19dcecdb2341e467885a`。專案工具環境內的依賴為 numpy 2.5.4、Pillow 12.3.0、PyYAML 6.0.3。解譯器使用已存在的獨立 Python 3.12.9，不是 ComfyUI venv；未安裝新 Python、uv 或 Agent plugin，未改全域 PATH。

ComfyUI 的獨立既有環境回應 Python 3.12.11、Torch 2.10.0+cu130；安裝前後與圖片測試後均維持相同版本。保護比對不包含所有執行中日誌／資料庫，不做完整系統零變更保證。

## 圖片與資源

測試前確認 ComfyUI queue 為空；可用顯存約 1.18 GiB、RAM 約 3 GiB。使用官方 `POST /free` 卸載暫存模型與清除執行快取後，可用顯存約 10.63 GiB、RAM 約 13.81 GiB，之後提交一次本地圖片任務。未重啟服務或修改安裝／設定；記憶體快取已重新建立。

- Workflow SHA256：`f0d80d92172a8dd7b371fdf673ff129fea2796aadb4d266571befe6a887f9c1e`。
- 圖片 SHA256：`6a590886b5173570d3d7f8880b2842994def6e5d73608b54d19ebb8631d3dfeb`。
- ComfyUI history：completed=true、status=success；manifest 的 workflow 與核准 JSON 一致。
- SaveImage 在 ComfyUI output 建立一張測試圖，CLI 將其複製到專案忽略的素材目錄。這些新增輸出留在本機。
- 未呼叫 fal 或其他付費 API，未下載模型，未執行 H3／WanVideo／Blender 渲染。

## 下一步

保留私人實跑證據與保護基準。先做獨立程式／結果審查，再評估原工作流功能回歸或 P3 素材處理；必須依新的任務範圍取得授權。依賴解析仍沒有 lockfile，重裝或換機需重新驗證。

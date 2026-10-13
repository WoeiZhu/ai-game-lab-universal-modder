# 架構與分工

需求 → 實作者 → Git commit → 獨立審查 → 專案專用 `um` CLI → 本地 ComfyUI／Blender → 隔離測試素材或單機 Mod → 真實驗收。

公開 Git 儲存可重用操作範本；私人儲存空間保存交接、絕對路徑、環境報告、Workflow JSON、seed 與生成證據。Git 是程式變更的事實來源，禁止私人同步工具雙向覆寫同一份程式碼。

`uv tool install` 的工具環境與 cache 設在 `.local/uv/`；不在 ComfyUI venv 裡安裝，不修改全域 PATH 或 Agent plugin 設定。安裝後使用本專案 `um.exe`，避免誤用 PATH 中其他版本。

P2 只允許已審查的本地圖片工作流，不操作 H3／WanVideo。初期僅接受七種標準圖片節點；class 名稱 allowlist 不能取代人工確認伺服器上的實際節點實作。傳送前把核准的 bytes 保存為本機快照，核对 SHA256，再傳給 CLI。

`um comfy image` 的上游預設圖為 SD1.5／SDXL，不能推論支援任何影片模型。Blender 轉 sprite、遊戲修改與其他 CLI 功能留待 P3 之後。

GPU 排程需由 P0 實測再決定；不得同時堆疊 ComfyUI 與 Blender 重任務。Port 8000 為設定預期，未確認服務存在。

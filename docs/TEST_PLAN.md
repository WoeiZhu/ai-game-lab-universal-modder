# P0–P7 分階段測試

目前僅 GitHub 初始化；以下全部 **NOT_RUN**。儲存庫的靜態／模擬測試不屬於 P0 環境測試。

| 階段 | 執行範圍 | 驗收證據 | 進入條件 |
|---|---|---|---|
| P0 | 指定工具來源、保護目錄；選用查版本；記錄原環境 baseline | 私人 preflight.json、版本／Git SHA、原工作流狀態與人工檢查 | 使用者授權 P0；不安裝、不啟停服務 |
| P1 | 固定 commit 的 CLI 裝入專案專用 uv tool 環境 | 安裝退出碼、專案 um 路徑、--version、--help、依賴清單；保護環境前後一致 | P0 通過、Python 來源已審查、明確安裝授權 |
| P2a | loopback GET /system_stats | 回應版本、連線結果；没有提交任務 | P0 已確認正確 Port／伺服器；失敗不自行啟動 |
| P2b | 一張小型本地圖片，已審查 API JSON | Workflow SHA256、seed、圖片、manifest、退出碼、原工作流回歸與資源觀察 | P1／P2a 通過；獨立生成授權；現有模型與七種標準節點；無付費節點 |
| P3 | 透明 PNG／sprite sheet | 尺寸、透明度、2D 場景載入 | 素材合法；變更先備份 |
| P4 | Blender 版本與合法 GLB 轉 sprite | 方向、畫面、參數、效能 | 單獨授權，避免 GPU 競爭 |
| P5 | 自製 HTML／Unity 小功能 | 啟動、功能與回歸 | 隔離測試分支 |
| P6 | 已擁有的單機遊戲之一個 Mod | 載入、存檔備份、完整復原 | 明確遊戲修改授權與適用 Loader／條款 |
| P7 | commit、獨立審查與私人交接 | SHA、證據、未測項目與下一步 | 審查內容可追溯；不公開私人紀錄 |

## GitHub 初始化完成後的 P0–P2 順序

1. P0：先審查工具來源，再執行盤點。`-ProtectedEnvironmentPaths` 接受使用者提供的既有環境目錄；缺失不代表可建立或重裝。報告只做工具位置與選用版本查詢，不探查模型或秘密。人工記錄現有 ComfyUI／Torch／CUDA／H3／WanVideo baseline，原工作流回歸若需執行另取得授權。
2. P1：P0 的缺失項與風險解決後再授權安裝。使用 `-PythonExe` 指定已審查的非 ComfyUI 解譯器。腳本不改 PATH；缺 uv／git／Python、安裝失敗或任一 CLI 檢查失敗就停止。依賴解析未鎖定須列為剩餘風險。
3. P2：先只連線，再選現有已驗證模型，API JSON 使用 UTF-8 無 BOM，輸出單張、最大 512×512、最多 30 steps 的本地 smoke test。禁止新增節點或模型、H3／WanVideo、付費節點。檢查圖片與 manifest 後，再做已授權的原工作流回歸。逾時不重送，先查原任務是否仍在 queue。

P0 成功並不表示 H3／WanVideo 可用；工具版本成功也不表示 P1 完整環境回歸通過。L0 命令、L1 邏輯、L2 畫面、L3 功能、L4 數值、L5 回歸、L6 環境／資源逐項填 PASS / FAIL / SKIP / NOT_RUN。

## 復原

初始化文件可透過 Git revert 復原。P1 工具移除應在明確授權後以相同 `UV_TOOL_DIR`／`UV_TOOL_BIN_DIR` 執行 `uv tool uninstall universal-modder`；不改或清理任何既有 AI 目錄。生成輸出留在被忽略的 `assets/`，保留證據後再決定是否清理。

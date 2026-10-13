# 成本與風險

- 本次只讀來源、檢查程式及初始化 GitHub，沒有模型生成或付費 API 呼叫。
- 未來本地生成仍有電力、容量與既有工具成本。雲端生成禁用；不提供任何 API 憑證範例或 fal MCP 設定。
- 固定上游 commit 可限制程式來源漂移；transitive dependencies 尚未建立 lockfile。P1 前應記錄 Python／uv 版本與依賴解析結果，審查下載與 build 行為。
- 安裝腳本會下載上游套件與依賴，執行 build backend；目前未執行。專用 uv tool 環境限制依賴污染，但不能把第三方程式視為完全隔離沙箱。
- 禁用 Python 自動下載，必須明確選擇既有、非 ComfyUI venv 的解譯器。uv 或 Python 缺失時停止，不能順手安裝。
- P2 workflow 的節點 allowlist 與雜湊是基本防護，仍需人工審查實際註冊節點、圖內容和輸出。未知、自訂或付費節點一律拒絕。
- 原始盤點報告、workflow manifest 常含電腦名稱、路徑或提示詞，禁止提交。`.gitignore` 不會保護已追蹤檔案；每次推送仍需掃描 staged bytes 與 commit metadata。
- 若任何階段失敗，保留私人證據並停止，不自動升級 ComfyUI／Torch／CUDA 或修改現有工作流來補救。

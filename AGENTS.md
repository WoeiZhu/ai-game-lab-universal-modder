# AGENTS.md — 共用執行約束

本專案是操作計畫與安全範本。先讀 README、docs/TEST_PLAN.md、Git 狀態與使用者當前授權；不要將準備完成當成已部署。

- 目前只允許 GitHub 初始化與儲存庫檢查；本地 P0–P7 尚未授權執行。
- 不修改、升級、重裝或啟停既有 ComfyUI、Torch、CUDA、Custom Nodes、MiniMax H3、WanVideo、Blender。
- P0 預設僅發現工具；查版本會啟動程式，須審查來源。盤點報告含電腦名稱與絕對路徑，禁止提交。
- P1 必須有 P0 證據與使用者明確安裝授權；只使用專案專用 uv tool 環境，不能使用 ComfyUI Python venv。不能自行安裝 uv、Python 或其他缺失工具。
- P2a 只連 loopback 讀狀態；P2b 須另取得本地生成授權，審查 API workflow、SHA256、節點實作與 GPU 餘裕。不得提交付費／雲端 API 節點。
- 付費 API 預設禁用，不能猜測、尋找或寫入金鑰。安裝 CLI 不等於授權使用其所有命令或安裝 Agent plugin／fal MCP。
- 修改遊戲、Loader、登錄檔、鍵鼠操作、發布 Mod 需明確授權與備份；不規避反作弊、DRM 或擁有權校驗。
- 同一分支只由一位實作者寫入。Claude 可依 commit 做獨立審查，未做審查就不得宣稱已完成 Claude 審查。
- 公開 Git 只放經審查的文件與程式；不放私人交接、Drive ID／連結、憑證、本機報告、遊戲原檔或模型。
- 私人交接只新增、不覆寫；本儲存庫不追蹤交接紀錄，也不自動同步 Drive。

每次結果記錄日期、Git SHA、指令、退出碼、影響範圍、證據、未測事項、復原方法與下一步。使用 PASS / FAIL / SKIP / NOT_RUN；L0 命令成功不能替代 L2 畫面、L3 功能、L5 回歸與 L6 環境驗證。

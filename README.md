# AI Game Lab — Universal Modder

Windows 本地 AI 遊戲開發的公開操作範本，整合 Universal Modder CLI、既有 ComfyUI 與 Blender。此專案與 [upstream](https://github.com/rehan-remade/universal-modder) 獨立；不包含 upstream 程式碼、模型、遊戲原檔或私人交接紀錄。

2026-10-13 狀態：GitHub 初始化；**本地 P0–P7 全部 NOT_RUN**。腳本的語法與隔離測試通過不代表環境部署完成。

## 本次範圍

僅整理及提交文件、設定範例、安裝與測試腳本。未安裝 Universal Modder，未啟動或變更 ComfyUI、Torch、CUDA、Custom Nodes、MiniMax H3、WanVideo 或 Blender；未呼叫付費 API。

公開儲存庫只放可重用範本。憑證、本機路徑、盤點報告、工作流、生成素材與私人交接留在本機或私人儲存空間，切勿推送。

## 檔案

- `AGENTS.md`、`CLAUDE.md`：執行與審查約束。
- `scripts/00-Preflight.ps1`：P0 工具／指定路徑盤點，報告含私人資訊，僅本機保存。
- `scripts/10-Install-UM.ps1`：P1 安裝；預設 dry-run，需明確指定 `-Install`。
- `scripts/20-Test-ComfyUI.ps1`：P2 本機連線；提交工作流需獨立開關、審查與 SHA256。
- `scripts/30-Test-Blender.ps1`：選用版本查詢，不渲染。
- `config/.env.example`、`config/upstream.json`：空白設定與 upstream 基準。
- `docs/TEST_PLAN.md`：P0–P7 計畫；`docs/RESULT_TEMPLATE.md`：公開結果範本。
- `tests/`：不安裝工具、不接觸 ComfyUI 的儲存庫檢查。

## 後續操作範例（本次不執行）

先讀 [測試計畫](docs/TEST_PLAN.md)。在 PowerShell 5.1 或 7，以此儲存庫為工作目錄：

```powershell
git clone https://github.com/WoeiZhu/ai-game-lab-universal-modder.git
cd ai-game-lab-universal-modder

# P0：只查工具位置；可選傳入需保護的環境目錄。
.\scripts\00-Preflight.ps1
# -QueryVersions 才會啟動已存在的工具查版本；先審查其來源。

# P1：P0 驗收與明確安裝授權後，選擇既有且非 ComfyUI venv 的 Python。
# $pythonExe 應填入私人盤點報告中已審查的絕對路徑。
.\scripts\10-Install-UM.ps1 -Install -PythonExe $pythonExe

# P2a：僅 GET /system_stats，不提交任務，不啟動伺服器。
.\scripts\20-Test-ComfyUI.ps1

# P2b：先人工審查工作流與伺服器節點，取得本地生成授權。
$workflow = '.\workflows\comfy-api\smoke_api.json'
$hash = (Get-FileHash -LiteralPath $workflow -Algorithm SHA256).Hash
.\scripts\20-Test-ComfyUI.ps1 -WorkflowPath $workflow -WorkflowSha256 $hash -ExecuteWorkflow
```

`COMFYUI_URL` 範例是 `http://127.0.0.1:8000`，實際連線狀態尚未驗證。腳本只接受 HTTP 的數字 loopback 主機，拒絕憑證、查詢字串與路徑；不自動改 Port 或開放外網。

安裝固定 `config/upstream.json` 的 commit，工具環境、bin 與 cache 都在本專案 `.local/uv/`。不改全域 PATH；後續使用 `.local/uv/bin/um.exe`。依賴仍由 uv 解析，**尚未鎖定 transitive dependencies，也未驗證 Windows 安裝**。

`.env.example` 僅供參考，腳本不自動載入 `.env`。ComfyUI 位置透過 P0 的 `-ProtectedEnvironmentPaths` 傳入，Blender 位置透過 `-BlenderExe` 傳入，勿填進公開文件。

## 提交前驗證

```powershell
python .\tests\check_public_files.py
powershell -NoProfile -File .\tests\Test-Repository.ps1
git diff --check
```

檢查器僅輸出檔名、行號與規則，不回顯疑似秘密。仍需人工審查 staged diff、二進位檔與 commit metadata。

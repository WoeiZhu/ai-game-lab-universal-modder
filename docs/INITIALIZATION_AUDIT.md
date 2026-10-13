# 初始化審查紀錄 — 2026-10-13

本紀錄僅描述公開檔案整理與靜態／模擬驗證，不包含私人交接內容、Drive URL／ID、電腦名稱或絕對路徑。

## 範圍

原始導入套件共 14 個檔案，文件與腳本已全部讀取。公開版本排除整個私人交接目錄，改寫含私人路徑或早期部署假設的文件；新增空白結果範本及儲存庫檢查。兩份私人補充來源僅用於核對，不提交。

- API Key／Token：原套件未發現實際值；公開設定不含憑證欄位值。
- 路徑／私人記錄：移除寫死的環境與工作目錄、個人來源敘述、私人雲端路徑／連結及 unrelated repo 資訊。
- Git：只提交明確 allowlist 的 20 個公開文字檔；報告、workflow、工具環境、素材、模型、遊戲檔與來源壓縮包不追蹤。
- 安裝：預設 dry-run；固定 upstream commit；專案專用工具／bin／cache；缺失工具停止；檢查每個退出碼，不將 PATH 缺失當成成功。
- P2：loopback URL 限制、禁重新導向、工作流 hash、標準圖片節點 allowlist、單張小圖限制；人工審查仍必須執行。

## 驗證方法

`tests/check_public_files.py --staged` 檢查精確 index bytes、檔名 allowlist、常見秘密格式、私人 URL／路徑、email 及非文字檔；不回顯疑似值。`tests/test_public_check.py` 用合成資料確認偵測與去識別輸出。PowerShell 5.1／7 語法解析與 mock 測試確認預設不安裝、P2 僅 GET、本地 URL 防護及未核准 workflow 拒絕。

GitHub 推送後另以遠端 branch SHA、commit tree 與每個 blob 的 Git hash 比對本地 index，並掃描遠端讀回內容。最終 commit SHA 與結果由完成回報提供，避免文件自我引用 commit。

初始化本地檢查結果：20 個公開檔案模式掃描通過；7 項 Python 合成測試通過；PowerShell 5.1 與 7 各 26 項語法／防護／模擬檢查通過。GitHub 遠端查核另於推送後執行。

## 未驗證

Universal Modder 安裝、依賴解析、ComfyUI 連線、GPU 生成、原工作流回歸及 Blender 均未執行，P0–P7 = NOT_RUN。未做 Claude 獨立審查。靜態掃描不能證明不存在所有形式的秘密；公開前需人工檢查全部檔案與 commit metadata。

上游基準為 `config/upstream.json` 記錄的 commit，僅閱讀其套件 metadata、CLI 入口與相關模組；未執行或安裝 upstream。

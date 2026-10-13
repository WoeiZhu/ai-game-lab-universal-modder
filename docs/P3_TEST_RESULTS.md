# Codex 審查與 P3 測試結果 — 2026-10-13

執行基準：`c3ff85aa7f83ae267b1eb56f2ddbe8740a467f85`。本輪由目前 Codex 代理審查腳本與實跑證據；**獨立 Claude 簽核尚未執行**。

## 審查與修正

P0–P2 的來源 commit、CLI 隔離目錄、退出碼、workflow hash、圖片及前後保護比對均有私人證據。發現 P2 佇列與資源檢查僅由實作者人工執行，腳本本身尚未擋下不足資源；現已加入 queue 必須為空、單一 GPU 可用顯存與 RAM 各至少 4 GiB 的提交前檢查。模擬測試涵蓋資源不足與佇列非空；不自動卸載模型或取消其他任務。這只是狀態快照，不是資源預約。

剩餘限制：依賴沒有 lockfile；標準 node class allowlist 不能取代實際註冊節點審查；H3／WanVideo 功能回歸尚未執行。這些限制保留，不將單張圖片或檔案雜湊不變視為完整部署驗收。

## P3 範圍與成果

以 P2 自行生成的機器人 PNG 為來源，使用已安裝且固定 commit 的 `um sprite` CLI。原圖以 SHA256 固定，先複製到全新素材輸出目錄，所有處理只寫入新檔，沒有覆寫來源、其他素材或遊戲檔案。

| 項目 | 結果 | 證據 |
|---|---|---|
| 去背 | PASS | 產出 RGBA 圖，有透明與不透明像素；原圖 hash 不變 |
| 固定尺寸與鏡像 | PASS | 四份 64×64 sprite，二值 alpha；鏡像與原版逐像素一致 |
| 像素化 | PASS | 32×32，16 色量化加 1 色描邊，共 17 種可見顏色 |
| Sprite sheet | PASS | 2×2、128×128；每格為 64×64，包含原版／鏡像及像素版／鏡像 |
| 切片 roundtrip | PASS | 四格切回後與原 sprite 的 RGBA bytes 完全一致 |
| 目視檢查 | PASS（smoke 範圍） | 棋盤背景可見透明區、機器人可辨識；不是正式遊戲美術品質簽核 |
| 瀏覽器場景 | PASS | Canvas 從 sheet 載入；左右移動、鏡像、像素切換及重設成功；透明角落保留背景，角色像素確實繪出 |

來源 SHA256：`6a590886b5173570d3d7f8880b2842994def6e5d73608b54d19ebb8631d3dfeb`。素材、來源副本、PNG 預覽、逐檔 hash、原始日志及瀏覽器截圖留在本機忽略目錄；公開 Git 僅保存通用腳本、測試頁及此去識別化紀錄。

與 P2 結束時的保護基準比對，7,168 個保護檔案 hash 與 244 個模型的大小／mtime 均無差異。本輪沒有提交 ComfyUI 任務或呼叫付費 API。新版 P2 資源檢查另以即時唯讀狀態回應通過驗證。

## 重現方式

```powershell
$source = '.\assets\concepts\smoke-test.png'
$hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
.\scripts\40-Test-Sprite.ps1 -Execute -SourcePath $source -SourceSha256 $hash
# 使用上一命令的新輸出目錄中的 robot-sheet.png：
python .\tests\serve_sprite_preview.py --sheet $sheetPath
```

預覽伺服器只綁 loopback，僅提供測試 HTML 與指定 PNG，不提供目錄瀏覽、報告、設定或 Git 內容。P3 腳本預設 dry-run，輸出必須位於專案 assets 的全新子目錄。

P4–P7 與 H3／WanVideo 功能回歸仍為 NOT_RUN。下一階段為 P4 的合法 GLB／Blender smoke test，需先確定獨立執行範圍與輸入模型。

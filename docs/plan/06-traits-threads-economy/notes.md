# Technical Notes — MODULE 06: `06-traits-threads-economy`

- **Zero Boots & Zero P2W Mutations:** `ThreadConfigs.luau` และ `TraitAndThreadService.luau` ไม่มีระบบรองเท้าสตั๊ด และ `MutationPresets` บวกเฉพาะ VFX, มูลค่าเทรด, และตัวคูณ Cash (`x1.5–x5.0`) / EXP (`x1.5–x3.0`) หลังจบแมตช์เท่านั้น
- **Server Trait Cooldown:** `TraitAndThreadService.ActivateTrait` ตรวจสอบเวลาคูลดาวน์บน Server ด้วย `os.clock()` เสมอ
- **2-Step P2P Trade & Anti-Dupe Lock:** `TradeMarketService.HandleTradeAction` ล็อก `itemUid` ทันทีที่วางเทรด รีเซ็ตสถานะ Lock หากมีการเพิ่มของ และบังคับรอนับถอยหลัง `3.0 วินาที` หลัง `LockOffer` ครบ 2 ฝั่งก่อนอนุญาตให้ `ConfirmTrade`

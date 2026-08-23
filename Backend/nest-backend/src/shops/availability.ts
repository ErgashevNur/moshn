/**
 * Bo'sh vaqtlarni hisoblash (zapis ekrani uchun).
 *
 * Qoidalar:
 *  - Vaqtlar servisning ish vaqti ichida (`workingHours`, "HH:MM-HH:MM").
 *  - Slot qadamı 30 daqiqa; paket davomiyligi hisobga olinadi — ish yopilish
 *    vaqtidan oshib ketmasligi kerak.
 *  - Servisda bir nechta usta bo'lishi mumkin, shuning uchun slot faqat
 *    BARCHA faol ustalar band bo'lgandagina yopiladi.
 *  - O'tib ketgan vaqtlar ko'rsatilmaydi.
 *
 * O'zbekiston yozgi vaqtga o'tmaydi (doim UTC+5), shuning uchun qat'iy
 * siljish ishlatiladi — `Intl` bilan har slot uchun hisoblashdan sodda va
 * tezroq.
 */

export const TASHKENT_OFFSET_MIN = 5 * 60;
export const SLOT_STEP_MIN = 30;

const DEFAULT_OPEN_MIN = 9 * 60;
const DEFAULT_CLOSE_MIN = 18 * 60;

export interface WorkWindow {
  openMin: number;
  closeMin: number;
}

/// "09:00-18:00" → {540, 1080}. Format tanilmasa standart 09:00–18:00
/// (servis ma'lumotni to'ldirmagani uchun butunlay yashirilmasin).
export function parseWorkingHours(workingHours?: string | null): WorkWindow {
  const m = /^(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})$/.exec((workingHours ?? '').trim());
  if (!m) return { openMin: DEFAULT_OPEN_MIN, closeMin: DEFAULT_CLOSE_MIN };

  const openMin = Number(m[1]) * 60 + Number(m[2]);
  const closeMin = Number(m[3]) * 60 + Number(m[4]);
  // Tungi smena (20:00-02:00) yoki bir xil qiymat — kun bo'yicha slot
  // yasash mantiqiy emas, standartga qaytamiz.
  if (closeMin <= openMin) return { openMin: DEFAULT_OPEN_MIN, closeMin: DEFAULT_CLOSE_MIN };
  return { openMin, closeMin };
}

/// Toshkent vaqtidagi "YYYY-MM-DD" kunning boshlanishini UTC `Date` sifatida.
export function localDayStartUtc(dateStr: string): Date {
  const [y, mo, d] = dateStr.split('-').map(Number);
  return new Date(Date.UTC(y, mo - 1, d, 0, 0, 0) - TASHKENT_OFFSET_MIN * 60_000);
}

/// UTC `Date` → Toshkent vaqtidagi "YYYY-MM-DD".
export function localDateStr(utc: Date): string {
  const local = new Date(utc.getTime() + TASHKENT_OFFSET_MIN * 60_000);
  return local.toISOString().slice(0, 10);
}

export interface BusyInterval {
  startMs: number;
  endMs: number;
}

/**
 * Berilgan kun uchun bo'sh slotlarni qaytaradi (UTC `Date` ro'yxati).
 *
 * @param busy      shu servisdagi faol bronlar (boshlanish + davomiylik)
 * @param masters   faol ustalar soni (0 bo'lsa — hech qanday slot yo'q)
 */
export function freeSlotsForDay(params: {
  dateStr: string;
  workingHours?: string | null;
  durationMin: number;
  busy: BusyInterval[];
  masters: number;
  now?: Date;
}): Date[] {
  const { dateStr, workingHours, durationMin, busy, masters } = params;
  if (masters <= 0) return [];

  const now = params.now ?? new Date();
  const { openMin, closeMin } = parseWorkingHours(workingHours);
  const dayStart = localDayStartUtc(dateStr).getTime();

  const slots: Date[] = [];
  for (let m = openMin; m + durationMin <= closeMin; m += SLOT_STEP_MIN) {
    const startMs = dayStart + m * 60_000;
    if (startMs <= now.getTime()) continue; // o'tib ketgan vaqt

    const endMs = startMs + durationMin * 60_000;
    const overlapping = busy.filter((b) => b.startMs < endMs && startMs < b.endMs).length;
    if (overlapping < masters) slots.push(new Date(startMs));
  }
  return slots;
}

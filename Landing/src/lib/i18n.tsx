'use client'

import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from 'react'
import type { IconName } from '@/components/Icon'

export type Lang = 'uz' | 'ru'

export const LANGS: { code: Lang; label: string; short: string }[] = [
  { code: 'uz', label: "O‘zbekcha", short: 'UZ' },
  { code: 'ru', label: 'Русский', short: 'RU' },
]

type BenefitItem = { icon: IconName; title: string; desc: string }
type Stop = { tag: string | null; title: string; desc: string; cta?: boolean; ctaBtn?: string }

type Dict = {
  nav: { howItWorks: string; benefits: string; forClients: string; forServices: string; download: string; downloadApp: string }
  hero: { titlePre: string; titleHi: string; titlePost: string; subtitle: string; btnDownload: string; btnHow: string; scroll: string }
  journey: Stop[]
  benefits: {
    eyebrow: string
    title: string
    tabClients: string
    tabServices: string
    clients: BenefitItem[]
    services: BenefitItem[]
  }
  cta: { titlePre: string; titleHi: string; desc: string; btn: string; note: string }
  footer: { rights: string; howItWorks: string; download: string }
}

const uz: Dict = {
  nav: {
    howItWorks: 'Qanday ishlaydi',
    benefits: 'Afzalliklar',
    forClients: 'Mijozlar uchun',
    forServices: 'Servislar uchun',
    download: 'Yuklab olish',
    downloadApp: 'Ilovani yuklash',
  },
  hero: {
    titlePre: 'Eng yaqin shinomontajni',
    titleHi: 'bir necha bosishda',
    titlePost: 'toping',
    subtitle: 'Shina24 — mijoz va shinomontaj servislarini bog‘laydigan platforma.',
    btnDownload: 'Ilovani yuklab olish',
    btnHow: 'Qanday ishlaydi?',
    scroll: 'Pastga aylantiring',
  },
  journey: [
    {
      tag: '01 — TANLASH',
      title: 'Xizmat turini tanlang',
      desc: 'Podkachka, perezobuvka, disk ta’miri — kerakli xizmatni bosh ekranda darhol tanlaysiz.',
    },
    {
      tag: '02 — BRON',
      title: 'Navbatsiz bron qiling',
      desc: 'Xaritadan eng yaqin servisni topib, qulay sana va vaqtni tanlaysiz — sizni kutadi.',
    },
    {
      tag: '03 — TO‘LOV',
      title: 'QR orqali to‘g‘ridan to‘lang',
      desc: 'Xizmatdan so‘ng QR kod yoki naqd to‘lov, xohlasangiz ustaga tip qoldirasiz.',
    },
    {
      tag: null,
      title: 'Ilovani hoziroq yuklab oling',
      desc: 'Mijoz sifatida bron qiling yoki shinomontaj sifatida ro‘yxatga oling — bitta ilovada ikki rol.',
      cta: true,
      ctaBtn: 'Android uchun yuklab olish',
    },
  ],
  benefits: {
    eyebrow: 'Afzalliklar',
    title: 'Har ikki tomon uchun qulay',
    tabClients: 'Mijozlar uchun',
    tabServices: 'Servislar uchun',
    clients: [
      { icon: 'car', title: 'Avtomobil ro‘yxati', desc: 'Plaka raqami va foto bilan avtomobilingizni saqlang — har safar qayta kiritmang.' },
      { icon: 'mapPin', title: 'Yaqin servislar', desc: 'Geolokatsiya bo‘yicha eng yaqin va mos shinomontajlarni darhol ko‘rasiz.' },
      { icon: 'bell', title: 'Mavsum eslatmasi', desc: 'Qish/yoz fasli kelganda shina almashtirish vaqti haqida push-bildirishnoma olasiz.' },
      { icon: 'creditCard', title: 'Keyinroq to‘lash', desc: 'Xizmatni hozir oling, to‘lovni keyinroq amalga oshiring.' },
      { icon: 'star', title: 'Chayivoye (tip)', desc: 'Xizmatdan mamnun bo‘lsangiz, ustaga to‘g‘ridan-to‘g‘ri tip qoldirasiz.' },
    ],
    services: [
      { icon: 'clipboard', title: 'Real-vaqt bronlar', desc: 'Planshet/telefonga yangi bron, bekor qilish — barchasi jonli bildirishnoma orqali keladi.' },
      { icon: 'wallet', title: 'Planshetda to‘lov', desc: 'QR kod yoki karta orqali to‘lovni qabul qilasiz — terminal kabi qulay.' },
      { icon: 'users', title: 'Mijozlar CRM bazasi', desc: 'Telefon, ism, avtomobil, VIP belgisi va tashrif tarixi — barchasi bir joyda.' },
      { icon: 'chart', title: 'Statistika', desc: 'Bugun/hafta/oy bo‘yicha bronlar va daromad statistikasini kuzatib borasiz.' },
      { icon: 'star', title: 'Ikki tomonlama baho', desc: 'Siz ham mijozni baholaysiz — ishonchli va sifatli mijozlar bazasi shakllanadi.' },
    ],
  },
  cta: {
    titlePre: 'Shina24’ni hoziroq',
    titleHi: 'yuklab oling',
    desc: 'Mijoz sifatida bron qiling yoki shinomontaj sifatida o‘z servisingizni ro‘yxatga oling — bitta ilovada ikki rol.',
    btn: 'Android uchun yuklab olish (APK)',
    note: 'iOS versiyasi tez kunda. So‘rovlar uchun: support@shina24.uz',
  },
  footer: {
    rights: 'Barcha huquqlar himoyalangan.',
    howItWorks: 'Qanday ishlaydi',
    download: 'Yuklab olish',
  },
}

const ru: Dict = {
  nav: {
    howItWorks: 'Как это работает',
    benefits: 'Преимущества',
    forClients: 'Для клиентов',
    forServices: 'Для сервисов',
    download: 'Скачать',
    downloadApp: 'Скачать приложение',
  },
  hero: {
    titlePre: 'Найдите ближайший шиномонтаж',
    titleHi: 'в несколько кликов',
    titlePost: '',
    subtitle: 'Shina24 — платформа, соединяющая клиентов и шиномонтажные сервисы.',
    btnDownload: 'Скачать приложение',
    btnHow: 'Как это работает?',
    scroll: 'Прокрутите вниз',
  },
  journey: [
    {
      tag: '01 — ВЫБОР',
      title: 'Выберите тип услуги',
      desc: 'Подкачка, переобувка, ремонт дисков — нужную услугу выбираете сразу на главном экране.',
    },
    {
      tag: '02 — БРОНЬ',
      title: 'Бронируйте без очереди',
      desc: 'Находите на карте ближайший сервис и выбираете удобные дату и время — вас уже ждут.',
    },
    {
      tag: '03 — ОПЛАТА',
      title: 'Платите напрямую через QR',
      desc: 'После услуги — оплата по QR-коду или наличными, при желании оставляете чаевые мастеру.',
    },
    {
      tag: null,
      title: 'Скачайте приложение прямо сейчас',
      desc: 'Бронируйте как клиент или регистрируйтесь как шиномонтаж — две роли в одном приложении.',
      cta: true,
      ctaBtn: 'Скачать для Android',
    },
  ],
  benefits: {
    eyebrow: 'Преимущества',
    title: 'Удобно для обеих сторон',
    tabClients: 'Для клиентов',
    tabServices: 'Для сервисов',
    clients: [
      { icon: 'car', title: 'Список автомобилей', desc: 'Сохраните автомобиль с госномером и фото — не вводите данные каждый раз заново.' },
      { icon: 'mapPin', title: 'Ближайшие сервисы', desc: 'По геолокации сразу видите ближайшие и подходящие шиномонтажи.' },
      { icon: 'bell', title: 'Сезонное напоминание', desc: 'С приходом зимы или лета получаете push-уведомление о времени смены шин.' },
      { icon: 'creditCard', title: 'Оплата позже', desc: 'Получите услугу сейчас, а оплату совершите позже.' },
      { icon: 'star', title: 'Чаевые', desc: 'Если довольны услугой — оставляете чаевые мастеру напрямую.' },
    ],
    services: [
      { icon: 'clipboard', title: 'Брони в реальном времени', desc: 'Новая бронь, отмена — всё приходит на планшет или телефон живым уведомлением.' },
      { icon: 'wallet', title: 'Оплата на планшете', desc: 'Принимаете оплату по QR-коду или картой — удобно, как терминал.' },
      { icon: 'users', title: 'CRM база клиентов', desc: 'Телефон, имя, авто, VIP-отметка и история визитов — всё в одном месте.' },
      { icon: 'chart', title: 'Статистика', desc: 'Отслеживаете статистику броней и дохода за день, неделю и месяц.' },
      { icon: 'star', title: 'Двусторонняя оценка', desc: 'Вы тоже оцениваете клиента — формируется надёжная и качественная база.' },
    ],
  },
  cta: {
    titlePre: 'Скачайте Shina24',
    titleHi: 'прямо сейчас',
    desc: 'Бронируйте как клиент или зарегистрируйте свой шиномонтаж как сервис — две роли в одном приложении.',
    btn: 'Скачать для Android (APK)',
    note: 'Версия для iOS скоро. По вопросам: support@shina24.uz',
  },
  footer: {
    rights: 'Все права защищены.',
    howItWorks: 'Как это работает',
    download: 'Скачать',
  },
}

const DICTS: Record<Lang, Dict> = { uz, ru }

type Ctx = { lang: Lang; setLang: (l: Lang) => void; t: Dict }
const I18nContext = createContext<Ctx | null>(null)

export function I18nProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>('uz')

  useEffect(() => {
    const saved = window.localStorage.getItem('shina24-lang')
    if (saved === 'uz' || saved === 'ru') setLangState(saved)
  }, [])

  const setLang = useCallback((l: Lang) => {
    setLangState(l)
    window.localStorage.setItem('shina24-lang', l)
    document.documentElement.lang = l
  }, [])

  return <I18nContext.Provider value={{ lang, setLang, t: DICTS[lang] }}>{children}</I18nContext.Provider>
}

export function useI18n() {
  const ctx = useContext(I18nContext)
  if (!ctx) throw new Error('useI18n must be used within I18nProvider')
  return ctx
}

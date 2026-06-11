// moshn-i18n.jsx — bilingual strings (uz / ru)
const STR = {
  // ---- generic
  appName:       { uz: "Moshn", ru: "Moshn" },
  tagline:       { uz: "Mashina to‘xtadimi? Bir tugma — yordam yo‘lda.", ru: "Машина встала? Одна кнопка — помощь в пути." },
  continue:      { uz: "Davom etish", ru: "Продолжить" },
  next:          { uz: "Keyingi", ru: "Далее" },
  back:          { uz: "Orqaga", ru: "Назад" },
  done:          { uz: "Tayyor", ru: "Готово" },
  cancel:        { uz: "Bekor qilish", ru: "Отмена" },
  confirm:       { uz: "Tasdiqlash", ru: "Подтвердить" },
  skip:          { uz: "O‘tkazib yuborish", ru: "Пропустить" },
  save:          { uz: "Saqlash", ru: "Сохранить" },
  add:           { uz: "Qo‘shish", ru: "Добавить" },
  search:        { uz: "Qidirish", ru: "Поиск" },
  km:            { uz: "km", ru: "км" },
  min:           { uz: "daq", ru: "мин" },
  som:           { uz: "so‘m", ru: "сум" },
  from:          { uz: "dan", ru: "от" },

  // ---- onboarding
  ob1Title:      { uz: "Eng yaqin balon ustasi — qo‘l ostingizda", ru: "Ближайший шиномонтаж — под рукой" },
  ob1Sub:        { uz: "Xizmatni tanlang, narxni ko‘ring, vaqtga yoziling — bir necha tegishda.", ru: "Выберите услугу, сравните цены и забронируйте время за пару касаний." },
  ob2Title:      { uz: "Yo‘lda qoldingizmi? SOS bosing", ru: "Застряли на дороге? Нажмите SOS" },
  ob2Sub:        { uz: "Eng yaqin bo‘sh usta siz bilan to‘g‘ridan-to‘g‘ri bog‘lanadi va joyingizni ko‘radi.", ru: "Ближайший свободный мастер свяжется с вами и увидит вашу геопозицию." },
  ob3Title:      { uz: "Hozir yozeling — keyin to‘lang", ru: "Записывайтесь сейчас — платите позже" },
  ob3Sub:        { uz: "Bank va MKO bilan to‘lov, bo‘lib-bo‘lib to‘lash va chaevoy — hammasi ilovada.", ru: "Оплата через банк и МКО, рассрочка и чаевые — всё в приложении." },
  getStarted:    { uz: "Boshlash", ru: "Начать" },

  // ---- auth
  enterPhone:    { uz: "Telefon raqamingiz", ru: "Ваш номер телефона" },
  phoneHint:     { uz: "Kirish uchun SMS-kod yuboramiz", ru: "Отправим SMS-код для входа" },
  sendCode:      { uz: "Kod yuborish", ru: "Отправить код" },
  enterCode:     { uz: "Tasdiqlash kodi", ru: "Код подтверждения" },
  codeSentTo:    { uz: "Kod yuborildi:", ru: "Код отправлен на:" },
  resend:        { uz: "Qayta yuborish", ru: "Отправить снова" },
  resendIn:      { uz: "Qayta yuborish", ru: "Повторно через" },
  byContinuing:  { uz: "Davom etish orqali siz shartlarga rozilik bildirasiz", ru: "Продолжая, вы соглашаетесь с условиями" },

  // ---- home
  greeting:      { uz: "Assalomu alaykum", ru: "Здравствуйте" },
  whatService:   { uz: "Qanday xizmat kerak?", ru: "Какая услуга нужна?" },
  searchPh:      { uz: "Servis yoki manzil qidiring", ru: "Сервис или адрес" },
  nearYou:       { uz: "Yaqin atrofda", ru: "Рядом с вами" },
  popular:       { uz: "Shahardagi top servislar", ru: "Топ сервисы города" },
  seeMap:        { uz: "Xaritada ko‘rish", ru: "На карте" },
  seeAll:        { uz: "Barchasi", ru: "Все" },
  openNow:       { uz: "Hozir ochiq", ru: "Открыто" },
  closed:        { uz: "Yopiq", ru: "Закрыто" },
  reviews:       { uz: "sharh", ru: "отзывов" },

  // ---- services
  svc_pump:      { uz: "Havo to‘ldirish", ru: "Подкачка" },
  svc_swap:      { uz: "G‘ildirak almashtirish", ru: "Переобувка" },
  svc_rim:       { uz: "Disk ta'mirlash", ru: "Ремонт дисков" },
  svc_balance:   { uz: "Balanslash", ru: "Балансировка" },
  svc_patch:     { uz: "Teshik yamash", ru: "Ремонт прокола" },
  svc_storage:   { uz: "Mavsumiy saqlash", ru: "Сезонное хранение" },
  svc_all:       { uz: "Hammasi", ru: "Все" },

  // ---- workshop detail
  about:         { uz: "Servis haqida", ru: "О сервисе" },
  services:      { uz: "Xizmatlar va narxlar", ru: "Услуги и цены" },
  schedule:      { uz: "Ish vaqti", ru: "График работы" },
  reviewsTitle:  { uz: "Sharhlar", ru: "Отзывы" },
  book:          { uz: "Vaqtga yozilish", ru: "Записаться" },
  callShop:      { uz: "Qo‘ng‘iroq", ru: "Позвонить" },
  route:         { uz: "Yo‘nalish", ru: "Маршрут" },

  // ---- booking
  chooseService: { uz: "Xizmatni tanlang", ru: "Выберите услугу" },
  chooseDate:    { uz: "Sana", ru: "Дата" },
  chooseTime:    { uz: "Bo‘sh vaqtlar", ru: "Свободное время" },
  today:         { uz: "Bugun", ru: "Сегодня" },
  tomorrow:      { uz: "Ertaga", ru: "Завтра" },
  yourCar:       { uz: "Avtomobilingiz", ru: "Ваш автомобиль" },
  slotHeld:      { uz: "Slot 5 daqiqaga band qilindi", ru: "Слот забронирован на 5 минут" },
  toPayment:     { uz: "To‘lovga o‘tish", ru: "К оплате" },

  // ---- payment
  payment:       { uz: "To‘lov", ru: "Оплата" },
  orderSummary:  { uz: "Buyurtma", ru: "Заказ" },
  payNow:        { uz: "Hozir to‘lash", ru: "Оплатить сейчас" },
  payLater:      { uz: "Keyin to‘lash", ru: "Оплатить позже" },
  installment:   { uz: "Bo‘lib to‘lash", ru: "Рассрочка" },
  payLaterDesc:  { uz: "Xizmatdan keyin 14 kun ichida", ru: "В течение 14 дней после услуги" },
  installmentDesc:{ uz: "3–6 oy, bank va MKO orqali", ru: "3–6 мес, через банк и МКО" },
  card:          { uz: "Karta", ru: "Карта" },
  selectCard:    { uz: "To‘lov usuli", ru: "Способ оплаты" },
  addTip:        { uz: "Ustaga chaevoy", ru: "Чаевые мастеру" },
  tipDesc:       { uz: "Ixtiyoriy — ustaga rahmat aytish", ru: "По желанию — поблагодарить мастера" },
  noTip:         { uz: "Yo‘q", ru: "Нет" },
  total:         { uz: "Jami", ru: "Итого" },
  confirmBooking:{ uz: "Bandlovni tasdiqlash", ru: "Подтвердить запись" },
  holdNotice:    { uz: "Mablag‘ xizmat tasdiqlangach yechiladi", ru: "Сумма спишется после подтверждения услуги" },

  // ---- confirmation
  booked:        { uz: "Yozildingiz!", ru: "Вы записаны!" },
  bookedSub:     { uz: "Servis so‘rovingizni qabul qildi. Eslatma yuboramiz.", ru: "Сервис принял запрос. Пришлём напоминание." },
  addCalendar:   { uz: "Kalendarga qo‘shish", ru: "В календарь" },
  viewBooking:   { uz: "Bandlovni ko‘rish", ru: "К записи" },

  // ---- SOS
  sosTitle:      { uz: "Favqulodda yordam", ru: "Экстренная помощь" },
  sosHold:       { uz: "Yordam chaqirish uchun bosib turing", ru: "Удерживайте, чтобы вызвать помощь" },
  sosCalling:    { uz: "Eng yaqin usta qidirilmoqda…", ru: "Ищем ближайшего мастера…" },
  sosConnected: { uz: "Usta topildi", ru: "Мастер найден" },
  sosOnWay:      { uz: "Sizga yo‘l oldi", ru: "Выехал к вам" },
  sosShareLoc:   { uz: "Joylashuvingiz uzatilmoqda", ru: "Геопозиция передаётся" },
  videoCall:     { uz: "Video aloqa", ru: "Видеосвязь" },
  endCall:       { uz: "Tugatish", ru: "Завершить" },
  sosWhat:       { uz: "Nima bo‘ldi?", ru: "Что случилось?" },
  sos_flat:      { uz: "G‘ildirak teshildi", ru: "Прокол колеса" },
  sos_burst:     { uz: "G‘ildirak portladi", ru: "Лопнуло колесо" },
  sos_air:       { uz: "Havo tushdi", ru: "Спустило колесо" },
  sos_tool:      { uz: "Asbob yo‘q", ru: "Нет инструмента" },

  // ---- garage
  garage:        { uz: "Mening garajim", ru: "Мой гараж" },
  addCar:        { uz: "Avtomobil qo‘shish", ru: "Добавить авто" },
  plate:         { uz: "Davlat raqami", ru: "Гос. номер" },
  makeModel:     { uz: "Marka va model", ru: "Марка и модель" },
  wheelSize:     { uz: "G‘ildirak o‘lchami", ru: "Размер колёс" },
  carPhoto:      { uz: "Avtomobil fotosi", ru: "Фото авто" },
  callOwner:     { uz: "Raqam orqali bog‘lanish", ru: "Связь по номеру" },
  callOwnerDesc: { uz: "Boshqalar shoshilinch holatda raqamingiz orqali siz bilan bog‘lana oladi", ru: "Другие смогут связаться с вами по номеру в экстренной ситуации" },
  primary:       { uz: "Asosiy", ru: "Основной" },

  // ---- history & reviews
  history:       { uz: "Tashriflar tarixi", ru: "История визитов" },
  upcoming:      { uz: "Kelgusi", ru: "Предстоящие" },
  past:          { uz: "O‘tgan", ru: "Прошедшие" },
  leaveReview:   { uz: "Sharh qoldirish", ru: "Оставить отзыв" },
  rateVisit:     { uz: "Tashrifni baholang", ru: "Оцените визит" },
  rebook:        { uz: "Qayta yozilish", ru: "Записаться снова" },

  // ---- notifications
  notifications: { uz: "Bildirishnomalar", ru: "Уведомления" },
  seasonTitle:   { uz: "Mavsum keldi — g‘ildirakni almashtiring", ru: "Сезон пришёл — пора переобуваться" },
  seasonBody:    { uz: "Oxirgi tashrifdan 6 oy o‘tdi. Top servislarga oldindan yoziling.", ru: "С последнего визита прошло 6 месяцев. Запишитесь заранее в топ-сервисы." },
  bookNow:       { uz: "Hoziroq yozilish", ru: "Записаться" },

  // ---- profile / nav
  navHome:       { uz: "Asosiy", ru: "Главная" },
  navBookings:   { uz: "Yozuvlar", ru: "Записи" },
  navGarage:     { uz: "Garaj", ru: "Гараж" },
  navProfile:    { uz: "Profil", ru: "Профиль" },
  profile:       { uz: "Profil", ru: "Профиль" },
  settings:      { uz: "Sozlamalar", ru: "Настройки" },
  language:      { uz: "Til", ru: "Язык" },
  appearance:    { uz: "Ko‘rinish", ru: "Тема" },
  themeDark:     { uz: "Tungi", ru: "Тёмная" },
  themeLight:    { uz: "Kunduzgi", ru: "Светлая" },
  paymentMethods:{ uz: "To‘lov usullari", ru: "Способы оплаты" },
  myReviews:     { uz: "Sharhlarim", ru: "Мои отзывы" },
  help:          { uz: "Yordam", ru: "Поддержка" },
  logout:        { uz: "Chiqish", ru: "Выйти" },
  forPartners:   { uz: "Servislar uchun", ru: "Для сервисов" },
  partnerDesc:   { uz: "Planshet ilovasi — yozuvlar, terminal, mijozlar bazasi", ru: "Планшет — записи, терминал, база клиентов" },
};

function makeT(lang) {
  return (key) => {
    const v = STR[key];
    if (!v) return key;
    return v[lang] || v.uz || key;
  };
}

Object.assign(window, { STR, makeT });

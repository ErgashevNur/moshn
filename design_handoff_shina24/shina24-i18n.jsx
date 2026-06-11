// shina24-i18n.jsx — bilingual strings (uz / ru)
const STR = {
  // ---- generic
  appName:       { uz: "Shina24", ru: "Shina24" },
  tagline:       { uz: "Shinomontaj — tez, qulay, ishonchli.", ru: "Шиномонтаж — быстро, удобно, надёжно." },
  continue:      { uz: "Davom etish", ru: "Продолжить" },
  next:          { uz: "Keyingi", ru: "Далее" },
  back:          { uz: "Orqaga", ru: "Назад" },
  done:          { uz: "Tayyor", ru: "Готово" },
  cancel:        { uz: "Bekor qilish", ru: "Отмена" },
  confirm:       { uz: "Tasdiqlash", ru: "Подтвердить" },
  skip:          { uz: "O'tkazib yuborish", ru: "Пропустить" },
  save:          { uz: "Saqlash", ru: "Сохранить" },
  add:           { uz: "Qo'shish", ru: "Добавить" },
  search:        { uz: "Qidirish", ru: "Поиск" },
  km:            { uz: "km", ru: "км" },
  min:           { uz: "daq", ru: "мин" },
  som:           { uz: "so'm", ru: "сум" },
  from:          { uz: "dan", ru: "от" },
  edit:          { uz: "Tahrirlash", ru: "Редактировать" },

  // ---- role select
  chooseRole:    { uz: "Siz kim sifatida kirasiz?", ru: "Вы входите как?" },
  roleOwner:     { uz: "Avtomobil egasi", ru: "Владелец авто" },
  roleOwnerDesc: { uz: "Bronlash, to'lov, tarix", ru: "Запись, оплата, история" },
  roleService:   { uz: "Shinomontaj", ru: "Шиномонтаж" },
  roleServiceDesc:{ uz: "Bronlar qabul qilish, to'lov olish", ru: "Принимать записи, получать оплату" },

  // ---- onboarding
  ob1Title:      { uz: "Eng yaqin shinomontaj — qo'l ostingizda", ru: "Ближайший шиномонтаж — под рукой" },
  ob1Sub:        { uz: "Xizmatni tanlang, narxni ko'ring, vaqtga yoziling — bir necha tegishda.", ru: "Выберите услугу, сравните цены и запишитесь за пару касаний." },
  ob2Title:      { uz: "Sana va vaqtni o'zingiz tanlang", ru: "Выбирайте дату и время сами" },
  ob2Sub:        { uz: "Qulay vaqtni tanlang va shinomontaj sizni kutib olishga tayyor bo'ladi.", ru: "Выберите удобное время — сервис будет готов вас принять." },
  ob3Title:      { uz: "Hozir yozeling — xizmatdan keyin to'lang", ru: "Запишитесь сейчас — платите после" },
  ob3Sub:        { uz: "QR kod yoki karta bilan to'lov, bo'lib-bo'lib to'lash va ustaga chaevoy — hammasi ilovada.", ru: "QR-код, карта, рассрочка и чаевые мастеру — всё в приложении." },
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

  // ---- home (owner)
  whatService:   { uz: "Qanday xizmat kerak?", ru: "Какая услуга нужна?" },
  searchPh:      { uz: "Servis yoki manzil qidiring", ru: "Сервис или адрес" },
  nearYou:       { uz: "Yaqin atrofda", ru: "Рядом с вами" },
  popular:       { uz: "Shahardagi top servislar", ru: "Топ сервисы города" },
  seeMap:        { uz: "Xaritada ko'rish", ru: "На карте" },
  openNow:       { uz: "Ochiq", ru: "Открыто" },
  closed:        { uz: "Yopiq", ru: "Закрыто" },
  reviews:       { uz: "sharh", ru: "отзывов" },

  // ---- services
  svc_pump:      { uz: "Havo to'ldirish", ru: "Подкачка" },
  svc_swap:      { uz: "G'ildirak almashtirish", ru: "Переобувка" },
  svc_rim:       { uz: "Disk ta'mirlash", ru: "Ремонт дисков" },
  svc_balance:   { uz: "Balanslash", ru: "Балансировка" },
  svc_patch:     { uz: "Teshik yamash", ru: "Ремонт прокола" },
  svc_storage:   { uz: "Mavsumiy saqlash", ru: "Сезонное хранение" },

  // ---- service profile
  about:         { uz: "Servis haqida", ru: "О сервисе" },
  services:      { uz: "Xizmatlar va narxlar", ru: "Услуги и цены" },
  schedule:      { uz: "Ish vaqti", ru: "График работы" },
  reviewsTitle:  { uz: "Sharhlar", ru: "Отзывы" },
  book:          { uz: "Vaqtga yozilish", ru: "Записаться" },
  callShop:      { uz: "Qo'ng'iroq", ru: "Позвонить" },
  route:         { uz: "Yo'nalish", ru: "Маршрут" },

  // ---- booking
  chooseService: { uz: "Xizmatni tanlang", ru: "Выберите услугу" },
  chooseDate:    { uz: "Sana", ru: "Дата" },
  chooseTime:    { uz: "Bo'sh vaqtlar", ru: "Свободное время" },
  today:         { uz: "Bugun", ru: "Сегодня" },
  tomorrow:      { uz: "Ertaga", ru: "Завтра" },
  yourCar:       { uz: "Avtomobilingiz", ru: "Ваш автомобиль" },
  slotHeld:      { uz: "Slot 5 daqiqaga band qilindi", ru: "Слот забронирован на 5 минут" },
  toPayment:     { uz: "To'lovga o'tish", ru: "К оплате" },

  // ---- payment
  payment:       { uz: "To'lov", ru: "Оплата" },
  orderSummary:  { uz: "Buyurtma", ru: "Заказ" },
  payNow:        { uz: "Hozir to'lash", ru: "Оплатить сейчас" },
  payLater:      { uz: "Keyin to'lash", ru: "Оплатить позже" },
  installment:   { uz: "Bo'lib to'lash", ru: "Рассрочка" },
  payLaterDesc:  { uz: "Xizmatdan keyin 14 kun ichida", ru: "В течение 14 дней после услуги" },
  installmentDesc:{ uz: "3–6 oy, bank va MKO orqali", ru: "3–6 мес, через банк и МКО" },
  selectCard:    { uz: "To'lov usuli", ru: "Способ оплаты" },
  addTip:        { uz: "Ustaga chaevoy", ru: "Чаевые мастеру" },
  tipDesc:       { uz: "Ixtiyoriy — ustaga rahmat aytish", ru: "По желанию — поблагодарить мастера" },
  noTip:         { uz: "Yo'q", ru: "Нет" },
  total:         { uz: "Jami", ru: "Итого" },
  confirmBooking:{ uz: "Bandlovni tasdiqlash", ru: "Подтвердить запись" },
  holdNotice:    { uz: "Mablag' xizmat tasdiqlangach yechiladi", ru: "Сумма спишется после подтверждения услуги" },

  // ---- confirmation
  booked:        { uz: "Yozildingiz!", ru: "Вы записаны!" },
  bookedSub:     { uz: "Servis so'rovingizni qabul qildi. Eslatma yuboramiz.", ru: "Сервис принял запрос. Пришлём напоминание." },
  addCalendar:   { uz: "Kalendarga qo'shish", ru: "В календарь" },
  viewBooking:   { uz: "Bandlovni ko'rish", ru: "К записи" },

  // ---- owner bookings
  history:       { uz: "Tashriflar tarixi", ru: "История визитов" },
  upcoming:      { uz: "Kelgusi", ru: "Предстоящие" },
  past:          { uz: "O'tgan", ru: "Прошедшие" },
  leaveReview:   { uz: "Sharh qoldirish", ru: "Оставить отзыв" },
  rateVisit:     { uz: "Tashrifni baholang", ru: "Оцените визит" },
  rebook:        { uz: "Qayta yozilish", ru: "Записаться снова" },

  // ---- vehicles / garage
  myVehicles:    { uz: "Avtomobillarim", ru: "Мои авто" },
  addCar:        { uz: "Avtomobil qo'shish", ru: "Добавить авто" },
  plate:         { uz: "Davlat raqami", ru: "Гос. номер" },
  makeModel:     { uz: "Marka va model", ru: "Марка и модель" },
  wheelSize:     { uz: "G'ildirak o'lchami", ru: "Размер колёс" },
  carPhoto:      { uz: "Avtomobil fotosi", ru: "Фото авто" },
  callOwner:     { uz: "Raqam orqali bog'lanish", ru: "Связь по номеру" },
  callOwnerDesc: { uz: "Boshqalar shoshilinch holatda raqamingiz orqali siz bilan bog'lana oladi", ru: "Другие смогут связаться с вами по номеру в экстренной ситуации" },
  primary:       { uz: "Asosiy", ru: "Основной" },

  // ---- notifications
  notifications: { uz: "Bildirishnomalar", ru: "Уведомления" },
  seasonTitle:   { uz: "Mavsum keldi — g'ildirakni almashtiring", ru: "Сезон пришёл — пора переобуваться" },
  seasonBody:    { uz: "Oxirgi tashrifdan 6 oy o'tdi. Top servislarga oldindan yoziling.", ru: "С последнего визита прошло 6 месяцев. Запишитесь заранее в топ-сервисы." },
  bookNow:       { uz: "Hoziroq yozilish", ru: "Записаться" },

  // ---- profile / nav (owner)
  navHome:       { uz: "Asosiy", ru: "Главная" },
  navBookings:   { uz: "Yozuvlar", ru: "Записи" },
  navVehicles:   { uz: "Avtomobil", ru: "Авто" },
  navProfile:    { uz: "Profil", ru: "Профиль" },
  profile:       { uz: "Profil", ru: "Профиль" },
  language:      { uz: "Til", ru: "Язык" },
  appearance:    { uz: "Ko'rinish", ru: "Тема" },
  themeDark:     { uz: "Tungi", ru: "Тёмная" },
  themeLight:    { uz: "Kunduzgi", ru: "Светлая" },
  paymentMethods:{ uz: "To'lov usullari", ru: "Способы оплаты" },
  myReviews:     { uz: "Sharhlarim", ru: "Мои отзывы" },
  help:          { uz: "Yordam", ru: "Поддержка" },
  logout:        { uz: "Chiqish", ru: "Выйти" },

  // ---- service side nav
  navToday:      { uz: "Bugun", ru: "Сегодня" },
  navAllBooks:   { uz: "Bronlar", ru: "Записи" },
  navCustomers:  { uz: "Mijozlar", ru: "Клиенты" },
  navStats:      { uz: "Statistika", ru: "Статистика" },

  // ---- service dashboard
  todayBookings: { uz: "Bugungi bronlar", ru: "Записи на сегодня" },
  newBookingIncoming: { uz: "Yangi bron!", ru: "Новая запись!" },
  confirmBookingAction: { uz: "Qabul qilish", ru: "Принять" },
  rejectBooking: { uz: "Rad etish", ru: "Отклонить" },
  noTodayBookings: { uz: "Bugun bron yo'q", ru: "На сегодня записей нет" },
  bookingPending:  { uz: "Kutilmoqda", ru: "Ожидает" },
  bookingConfirmed:{ uz: "Tasdiqlangan", ru: "Подтверждён" },
  bookingInProgress:{ uz: "Jarayonda", ru: "В процессе" },
  bookingCompleted:{ uz: "Bajarildi", ru: "Завершён" },
  bookingCancelled:{ uz: "Bekor qilingan", ru: "Отменён" },

  // ---- service booking detail
  bookingDetails:{ uz: "Bron tafsilotlari", ru: "Детали записи" },
  customerInfo:  { uz: "Mijoz", ru: "Клиент" },
  vehicleInfo:   { uz: "Avtomobil", ru: "Автомобиль" },
  startService:  { uz: "Xizmatni boshlash", ru: "Начать обслуживание" },
  finishService: { uz: "Bajarildi", ru: "Готово" },
  takePayment:   { uz: "To'lovni olish", ru: "Принять оплату" },
  cancelBooking: { uz: "Bekor qilish", ru: "Отменить" },

  // ---- payment receipt (service side)
  paymentReceipt:{ uz: "To'lov qabul qilish", ru: "Приём оплаты" },
  qrPayment:     { uz: "QR to'lov", ru: "Оплата QR" },
  cashPayment:   { uz: "Naqd", ru: "Наличные" },
  generateQR:    { uz: "QR yaratish", ru: "Создать QR" },
  qrHint:        { uz: "Mijoz ushbu QR kodni telefonida skanerlasin", ru: "Пусть клиент отсканирует этот QR телефоном" },
  paymentReceived:{ uz: "To'lov qabul qilindi", ru: "Оплата получена" },
  receivePayment:{ uz: "To'lovni tasdiqlash", ru: "Подтвердить оплату" },

  // ---- CRM
  customers:     { uz: "Mijozlar bazasi", ru: "База клиентов" },
  searchCustomer:{ uz: "Mijoz qidiring...", ru: "Поиск клиента..." },
  vipMark:       { uz: "VIP belgilash", ru: "Отметить VIP" },
  removeVip:     { uz: "VIP olib tashlash", ru: "Убрать VIP" },
  notes:         { uz: "Eslatma", ru: "Заметка" },
  notesPlaceholder:{ uz: "Mijoz haqida eslatma...", ru: "Заметка о клиенте..." },
  visitCount:    { uz: "Tashriflar", ru: "Визиты" },
  lastVisit:     { uz: "Oxirgi tashrif", ru: "Последний визит" },
  customerCard:  { uz: "Mijoz kartochkasi", ru: "Карточка клиента" },
  noCustomers:   { uz: "Hali mijoz yo'q", ru: "Клиентов пока нет" },

  // ---- statistics
  statistics:    { uz: "Statistika", ru: "Статистика" },
  statToday:     { uz: "Bugun", ru: "Сегодня" },
  statWeek:      { uz: "Hafta", ru: "Неделя" },
  statMonth:     { uz: "Oy", ru: "Месяц" },
  totalRevenue:  { uz: "Jami daromad", ru: "Выручка" },
  totalBookings: { uz: "Bronlar", ru: "Записей" },
  avgRating:     { uz: "Reyting", ru: "Рейтинг" },
  topServices:   { uz: "Top xizmatlar", ru: "Топ услуг" },
  revenueChart:  { uz: "Kunlik daromad", ru: "Дневная выручка" },

  // ---- service profile (service side)
  serviceProfile:{ uz: "Ustaxona profili", ru: "Профиль сервиса" },
  serviceName:   { uz: "Ustaxona nomi", ru: "Название сервиса" },
  serviceAddress:{ uz: "Manzil", ru: "Адрес" },
  workingHours:  { uz: "Ish vaqti", ru: "Часы работы" },
  serviceTypes:  { uz: "Xizmat turlari", ru: "Виды услуг" },
  isOpen:        { uz: "Hozir ochiq", ru: "Открыто сейчас" },
  forOwners:     { uz: "Mijozlar uchun", ru: "Для клиентов" },
  ownerDesc:     { uz: "Mijoz ilovasi — bron qilish, to'lov", ru: "Приложение клиента — запись, оплата" },
};

function makeT(lang) {
  return (key) => {
    const v = STR[key];
    if (!v) return key;
    return v[lang] || v.uz || key;
  };
}

Object.assign(window, { STR, makeT });

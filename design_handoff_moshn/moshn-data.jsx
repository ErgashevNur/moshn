// moshn-data.jsx — mock content for the prototype
const SERVICES = [
  { id: "swap",    icon: "snow",  key: "svc_swap",    price: 80000,  dur: 40 },
  { id: "pump",    icon: "gauge", key: "svc_pump",    price: 15000,  dur: 10 },
  { id: "patch",   icon: "wrench",key: "svc_patch",   price: 35000,  dur: 25 },
  { id: "balance", icon: "disc",  key: "svc_balance", price: 60000,  dur: 30 },
  { id: "rim",     icon: "disc",  key: "svc_rim",     price: 120000, dur: 60 },
  { id: "storage", icon: "layers",key: "svc_storage", price: 200000, dur: 15 },
];

const WORKSHOPS = [
  {
    id: "w1", name: "Shinmaster Pro", area: "Yunusobod, Amir Temur 108",
    rating: 4.9, reviews: 342, dist: 0.8, eta: 4, open: true,
    price: 70000, tags: ["vip"], lat: 41.34, lon: 69.28,
    desc: { uz: "Premium darajadagi balon markazi. Yevropa uskunalari, original balanslash stendi va kafolatli xizmat.", ru: "Шиномонтаж премиум-класса. Европейское оборудование, оригинальный балансировочный стенд и гарантия." },
    hours: "08:00 – 22:00", masters: 4,
  },
  {
    id: "w2", name: "Avto Shina 24/7", area: "Chilonzor, Bunyodkor 12",
    rating: 4.7, reviews: 198, dist: 1.4, eta: 7, open: true,
    price: 55000, tags: ["24h"], lat: 41.29, lon: 69.20,
    desc: { uz: "Tunu-kun ishlaydigan servis. Tezkor g‘ildirak almashtirish va yo‘l yonda yordam.", ru: "Круглосуточный сервис. Быстрая переобувка и помощь на дороге." },
    hours: "24 soat", masters: 3,
  },
  {
    id: "w3", name: "Disk & Tire Center", area: "Mirzo Ulug‘bek, Buyuk Ipak 45",
    rating: 4.8, reviews: 256, dist: 2.1, eta: 9, open: true,
    price: 65000, tags: [], lat: 41.33, lon: 69.34,
    desc: { uz: "Disklarni tiklash va to‘g‘rilash bo‘yicha mutaxassis. Tokarlik stanogi mavjud.", ru: "Специалисты по восстановлению и правке дисков. Есть токарный станок." },
    hours: "09:00 – 20:00", masters: 5,
  },
  {
    id: "w4", name: "Tezkor Balon", area: "Sergeli, Yangi Sergeli 7",
    rating: 4.5, reviews: 121, dist: 3.0, eta: 12, open: false,
    price: 45000, tags: ["budget"], lat: 41.22, lon: 69.21,
    desc: { uz: "Hamyonbop narxlar, tez xizmat. Mahalla ichidagi ishonchli usta.", ru: "Доступные цены, быстрое обслуживание. Надёжный мастер в районе." },
    hours: "08:00 – 19:00", masters: 2,
  },
];

const REVIEWS = [
  { id: 1, name: "Sardor A.", rating: 5, ago: { uz: "2 kun oldin", ru: "2 дня назад" },
    text: { uz: "Tez va sifatli. 15 daqiqada to‘rt g‘ildirakni almashtirishdi.", ru: "Быстро и качественно. За 15 минут переобули все четыре колеса." } },
  { id: 2, name: "Dilnoza K.", rating: 5, ago: { uz: "1 hafta oldin", ru: "неделю назад" },
    text: { uz: "Chaevoyni ilovadan qoldirdim — juda qulay. Usta professional.", ru: "Оставила чаевые прямо в приложении — очень удобно. Мастер профи." } },
  { id: 3, name: "Jasur M.", rating: 4, ago: { uz: "2 hafta oldin", ru: "2 недели назад" },
    text: { uz: "Balanslash zo‘r bo‘ldi, lekin biroz kutishga to‘g‘ri keldi.", ru: "Балансировка отличная, но пришлось немного подождать." } },
];

const CARS = [
  { id: "c1", plate: "01 A 777 AA", make: "Chevrolet Cobalt", size: "R15 185/65", primary: true, color: "#d8d8d4" },
  { id: "c2", plate: "01 B 245 BC", make: "Toyota Camry", size: "R17 215/55", primary: false, color: "#1c1c1c" },
];

const BOOKINGS = [
  { id: "b1", shop: "Shinmaster Pro", svc: "svc_swap", date: { uz: "Bugun, 16:30", ru: "Сегодня, 16:30" },
    status: "upcoming", price: 80000, car: "01 A 777 AA" },
  { id: "b2", shop: "Avto Shina 24/7", svc: "svc_patch", date: { uz: "12-noyabr, 11:00", ru: "12 ноября, 11:00" },
    status: "past", price: 35000, car: "01 A 777 AA", rated: 5 },
  { id: "b3", shop: "Disk & Tire Center", svc: "svc_balance", date: { uz: "3-oktabr, 14:00", ru: "3 октября, 14:00" },
    status: "past", price: 60000, car: "01 B 245 BC", rated: 0 },
];

const PAY_METHODS = [
  { id: "uzcard", name: "UZCARD", num: "•••• 4417", brand: "uzcard" },
  { id: "humo",   name: "HUMO",   num: "•••• 8830", brand: "humo" },
  { id: "visa",   name: "VISA",   num: "•••• 2261", brand: "visa" },
];

const fmtSom = (n) => n.toLocaleString("ru-RU").replace(/,/g, " ");
const DATES = [
  { d: 6,  wd: { uz: "Pay", ru: "Пн" }, label: "today" },
  { d: 7,  wd: { uz: "Sesh", ru: "Вт" }, label: "tomorrow" },
  { d: 8,  wd: { uz: "Chor", ru: "Ср" } },
  { d: 9,  wd: { uz: "Pay", ru: "Чт" } },
  { d: 10, wd: { uz: "Jum", ru: "Пт" } },
  { d: 11, wd: { uz: "Shan", ru: "Сб" } },
  { d: 12, wd: { uz: "Yak", ru: "Вс" } },
];
const TIMES = ["09:00","09:30","10:00","11:00","11:30","13:00","14:30","15:00","16:30","17:00","18:00","19:30"];
const BOOKED_TIMES = ["10:00","13:00","17:00"];

Object.assign(window, { SERVICES, WORKSHOPS, REVIEWS, CARS, BOOKINGS, PAY_METHODS, fmtSom, DATES, TIMES, BOOKED_TIMES });

export const SVC_MAP: Record<string,{name:string;short:string;price:number}> = {
  swap:    {name:'Замена колеса',     short:'Замена',     price:80000},
  pump:    {name:'Подкачка шин',      short:'Подкачка',    price:15000},
  patch:   {name:'Заклейка прокола',  short:'Заклейка',    price:35000},
  balance: {name:'Балансировка',      short:'Баланс',      price:60000},
  rim:     {name:'Ремонт диска',      short:'Диск',        price:120000},
  storage: {name:'Сезонное хранение', short:'Хранение',    price:200000},
}

export const initQueue = [
  {id:'b1',name:'Akmal Karimov',   plate:'01 A 777 AA',car:'Cobalt',  svc:'swap',   time:'09:00',status:'done',      paid:true, amt:80000, rating:5,    vip:true, phone:'+998 90 123-45-67'},
  {id:'b2',name:'Sardor Baxtiyorov',plate:'10 B 321 BC',car:'Nexia 3',svc:'patch',  time:'09:30',status:'active',    paid:false,amt:35000, rating:null,  vip:false,phone:'+998 94 321-12-34'},
  {id:'b3',name:'Dilnoza Mirzayeva',plate:'01 K 455 KA',car:'Malibu', svc:'balance',time:'11:00',status:'confirmed', paid:false,amt:60000, rating:null,  vip:true, phone:'+998 93 456-78-90'},
  {id:'b4',name:'Jasur Toshmatov', plate:'30 C 112 CD',car:'Cobalt',  svc:'swap',   time:'11:30',status:'confirmed', paid:false,amt:80000, rating:null,  vip:false,phone:'+998 97 567-89-01'},
  {id:'b5',name:'Nodira Yusupova', plate:'01 M 888 MK',car:'Spark',   svc:'pump',   time:'13:00',status:'confirmed', paid:false,amt:15000, rating:null,  vip:false,phone:'+998 98 765-43-21'},
  {id:'b6',name:'Bobur Aliyev',    plate:'01 N 234 NB',car:'Camry',   svc:'rim',    time:'14:00',status:'confirmed', paid:false,amt:120000,rating:null,  vip:true, phone:'+998 91 234-56-78'},
  {id:'b7',name:'Zafar Xoliqov',   plate:'25 A 009 AB',car:'Lacetti', svc:'storage',time:'15:30',status:'confirmed', paid:false,amt:200000,rating:null,  vip:false,phone:'+998 90 789-01-23'},
  {id:'b8',name:'Shahnoza Rahimova',plate:'01 B 567 BA',car:'Damas',  svc:'patch',  time:'17:00',status:'confirmed', paid:false,amt:35000, rating:null,  vip:false,phone:'+998 91 890-12-34'},
]

export const initCustomers = [
  {id:'c1',name:'Akmal Karimov',   phone:'+998 90 123-45-67',plate:'01 A 777 AA',car:'Cobalt',  visits:12,total:980000, vip:true, rating:4.9,last:'Сегодня'},
  {id:'c2',name:'Bobur Aliyev',    phone:'+998 91 234-56-78',plate:'01 N 234 NB',car:'Camry',   visits:8, total:740000, vip:true, rating:5.0,last:'3 дня'},
  {id:'c3',name:'Dilnoza Mirzayeva',phone:'+998 93 345-67-89',plate:'01 K 455 KA',car:'Malibu', visits:6, total:480000, vip:true, rating:4.8,last:'Сегодня'},
  {id:'c4',name:'Sardor Baxtiyorov',phone:'+998 94 456-78-90',plate:'10 B 321 BC',car:'Nexia 3',visits:4, total:210000, vip:false,rating:4.5,last:'Сегодня'},
  {id:'c5',name:'Jasur Toshmatov', phone:'+998 97 567-89-01',plate:'30 C 112 CD',car:'Cobalt',  visits:3, total:240000, vip:false,rating:4.7,last:'2 недели'},
  {id:'c6',name:'Nodira Yusupova', phone:'+998 98 678-90-12',plate:'01 M 888 MK',car:'Spark',   visits:1, total:15000,  vip:false,rating:null as any,last:'Сегодня'},
  {id:'c7',name:'Zafar Xoliqov',   phone:'+998 90 789-01-23',plate:'25 A 009 AB',car:'Lacetti', visits:2, total:235000, vip:false,rating:4.6,last:'1 месяц'},
  {id:'c8',name:'Shahnoza Rahimova',phone:'+998 91 890-12-34',plate:'01 B 567 BA',car:'Damas',  visits:5, total:175000, vip:false,rating:4.8,last:'1 неделя'},
]

export const SC: Record<string,{dot:string;label:string;bg:string;clr:string}> = {
  done:      {dot:'var(--green)', label:'Готово',     bg:'var(--greenDim)', clr:'var(--green)'},
  active:    {dot:'var(--amber)', label:'В процессе', bg:'var(--amberDim)', clr:'var(--amber)'},
  confirmed: {dot:'var(--txt3)',  label:'Ожидание',   bg:'rgba(244,244,242,.08)', clr:'var(--txt2)'},
  cancelled: {dot:'var(--red)',   label:'Отменено',   bg:'var(--redDim)', clr:'var(--red)'},
}

export const fmt = (n: number) => n.toLocaleString('ru-RU').replace(/,/g,' ')

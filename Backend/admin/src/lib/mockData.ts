export const W_DATA = [
  {id:'w1',name:'Shinmaster Pro',area:'Yunusobod',owner:'Bobur Aliyev',phone:'+998 91 234-56-78',rating:4.9,bookings:342,revenue:27360000,status:'active',joined:'2025-03'},
  {id:'w2',name:'Avto Shina 24/7',area:'Chilonzor',owner:'Sardor Nishonov',phone:'+998 93 345-67-89',rating:4.7,bookings:198,revenue:10890000,status:'active',joined:'2025-06'},
  {id:'w3',name:'Disk & Tire Center',area:"Mirzo Ulug'bek",owner:'Jasur Toshmatov',phone:'+998 90 456-78-90',rating:4.8,bookings:256,revenue:20480000,status:'active',joined:'2025-01'},
  {id:'w4',name:'Tezkor Balon',area:'Sergeli',owner:'Nodira Xoliqova',phone:'+998 98 567-89-01',rating:4.5,bookings:121,revenue:5445000,status:'active',joined:'2026-04'},
  {id:'w5',name:'Shina Markaz',area:'Uchtepa',owner:'Alisher Karimov',phone:'+998 97 678-90-12',rating:null as any,bookings:0,revenue:0,status:'pending',joined:'2026-05'},
  {id:'w6',name:'Premium Disk',area:'Yakkasaroy',owner:'Zafar Raximov',phone:'+998 90 789-01-23',rating:3.2,bookings:28,revenue:1120000,status:'suspended',joined:'2025-11'},
  {id:'w7',name:'Express Tire',area:'Bektemir',owner:'Shohruh Yunusov',phone:'+998 94 890-12-34',rating:null as any,bookings:0,revenue:0,status:'pending',joined:'2026-06'},
]

export const U_DATA = [
  {id:'u1',name:'Akmal Karimov',phone:'+998 90 123-45-67',plate:'01 A 777 AA',bookings:12,spent:980000,vip:true,joined:'2025-03'},
  {id:'u2',name:'Dilnoza Mirzayeva',phone:'+998 93 234-56-78',plate:'01 K 455 KA',bookings:8,spent:640000,vip:true,joined:'2025-05'},
  {id:'u3',name:'Bobur Aliyev',phone:'+998 91 456-78-90',plate:'01 N 234 NB',bookings:9,spent:860000,vip:true,joined:'2025-04'},
  {id:'u4',name:'Sardor Baxtiyorov',phone:'+998 94 345-67-89',plate:'10 B 321 BC',bookings:4,spent:210000,vip:false,joined:'2025-09'},
  {id:'u5',name:'Jasur Toshmatov',phone:'+998 97 567-89-01',plate:'30 C 112 CD',bookings:3,spent:240000,vip:false,joined:'2025-11'},
  {id:'u6',name:'Nodira Yusupova',phone:'+998 98 678-90-12',plate:'01 M 888 MK',bookings:1,spent:15000,vip:false,joined:'2026-06'},
  {id:'u7',name:'Zafar Xoliqov',phone:'+998 90 789-01-23',plate:'25 A 009 AB',bookings:2,spent:235000,vip:false,joined:'2026-01'},
  {id:'u8',name:'Shahnoza Rahimova',phone:'+998 91 890-12-34',plate:'01 B 567 BA',bookings:5,spent:175000,vip:false,joined:'2025-08'},
]

export const B_DATA = [
  {id:'bk001',user:'Akmal Karimov',shop:'Shinmaster Pro',svc:"G'ildirak almashtirish",date:'11.06 09:00',amt:80000,status:'done'},
  {id:'bk002',user:'Sardor Baxtiyorov',shop:'Avto Shina 24/7',svc:'Teshik yamash',date:'11.06 09:30',amt:35000,status:'active'},
  {id:'bk003',user:'Dilnoza Mirzayeva',shop:'Shinmaster Pro',svc:'Balanslash',date:'11.06 11:00',amt:60000,status:'confirmed'},
  {id:'bk004',user:'Bobur Aliyev',shop:'Disk & Tire Center',svc:"Disk ta'mirlash",date:'11.06 14:00',amt:120000,status:'confirmed'},
  {id:'bk005',user:'Nodira Yusupova',shop:'Tezkor Balon',svc:"Havo to'ldirish",date:'10.06 16:00',amt:15000,status:'done'},
  {id:'bk006',user:'Zafar Xoliqov',shop:'Avto Shina 24/7',svc:'Mavsumiy saqlash',date:'10.06 14:30',amt:200000,status:'done'},
  {id:'bk007',user:'Jasur Toshmatov',shop:'Shinmaster Pro',svc:"G'ildirak almashtirish",date:'09.06 10:00',amt:80000,status:'cancelled'},
  {id:'bk008',user:'Shahnoza Rahimova',shop:'Disk & Tire Center',svc:'Teshik yamash',date:'09.06 15:00',amt:35000,status:'done'},
]

export const WEEK = [2840000,3200000,2100000,4100000,3600000,5200000,3600000]
export const DAYS = ['Du','Se','Ch','Pa','Ju','Sh','Ya']
export const MONTHS = [18.2,22.4,19.8,28.6,24.1,31.2,28.8,35.4,30.2,38.1,32.5,24.8]
export const MN = ['Y','F','M','A','M','I','Iy','Av','S','O','N','D']

export const SC_B: Record<string,{l:string;c:string}> = {
  done:{l:'Tugadi',c:'b-green'},
  active:{l:'Jarayonda',c:'b-amber'},
  confirmed:{l:'Kutmoqda',c:'b-blue'},
  cancelled:{l:'Bekor',c:'b-red'},
}

export const fmtM = (n: number) =>
  n>=1000000 ? `${(n/1000000).toFixed(1)}M` : n>=1000 ? `${Math.round(n/1000)}K` : String(n)

export const fmt = (n: number) =>
  n.toLocaleString('ru-RU').replace(/,/g,' ')

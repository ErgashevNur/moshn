import axios from 'axios'

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/v1'

const partnerApi = axios.create({
  baseURL: API_URL,
  timeout: 30000,
  headers: { 'ngrok-skip-browser-warning': 'true' },
})

partnerApi.interceptors.request.use((config) => {
  if (typeof window !== 'undefined') {
    const token = localStorage.getItem('partner_access_token')
    if (token) config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

partnerApi.interceptors.response.use(
  (res) => res,
  async (error) => {
    if (error.response?.status === 401 && typeof window !== 'undefined') {
      const refresh = localStorage.getItem('partner_refresh_token')
      if (refresh) {
        try {
          const res = await axios.post(`${API_URL}/auth/refresh`, { refresh_token: refresh })
          const { access_token, refresh_token } = res.data.data
          localStorage.setItem('partner_access_token', access_token)
          localStorage.setItem('partner_refresh_token', refresh_token)
          error.config.headers.Authorization = `Bearer ${access_token}`
          return partnerApi(error.config)
        } catch {
          localStorage.removeItem('partner_access_token')
          localStorage.removeItem('partner_refresh_token')
          window.location.href = '/partner/login'
        }
      } else {
        window.location.href = '/partner/login'
      }
    }
    return Promise.reject(error)
  }
)

export default partnerApi

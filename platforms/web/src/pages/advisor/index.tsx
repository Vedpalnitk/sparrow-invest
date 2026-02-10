import { useEffect } from 'react'
import { useRouter } from 'next/router'

export default function AdvisorIndex() {
  const router = useRouter()

  useEffect(() => {
    router.replace('/advisor/login')
  }, [router])

  return null
}

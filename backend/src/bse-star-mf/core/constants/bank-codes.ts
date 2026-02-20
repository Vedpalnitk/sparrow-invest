export interface BseBankInfo {
  code: string
  name: string
  direct: boolean
  nodal: boolean
}

export const BSE_DIRECT_BANKS: BseBankInfo[] = [
  { code: 'HDF', name: 'HDFC Bank', direct: true, nodal: true },
  { code: 'ICI', name: 'ICICI Bank', direct: true, nodal: true },
  { code: 'AXI', name: 'Axis Bank', direct: true, nodal: true },
  { code: 'SBI', name: 'State Bank of India', direct: true, nodal: true },
  { code: 'KOT', name: 'Kotak Mahindra Bank', direct: true, nodal: true },
  { code: 'YBK', name: 'Yes Bank', direct: true, nodal: true },
]

export const BSE_NODAL_BANKS: BseBankInfo[] = [
  { code: 'BOB', name: 'Bank of Baroda', direct: false, nodal: true },
  { code: 'CAN', name: 'Canara Bank', direct: false, nodal: true },
  { code: 'PNB', name: 'Punjab National Bank', direct: false, nodal: true },
  { code: 'UBI', name: 'Union Bank of India', direct: false, nodal: true },
  { code: 'BOI', name: 'Bank of India', direct: false, nodal: true },
  { code: 'IDB', name: 'IDBI Bank', direct: false, nodal: true },
  { code: 'FBK', name: 'Federal Bank', direct: false, nodal: true },
  { code: 'INB', name: 'Indian Bank', direct: false, nodal: true },
  { code: 'IOB', name: 'Indian Overseas Bank', direct: false, nodal: true },
  { code: 'BDN', name: 'Bandhan Bank', direct: false, nodal: true },
  { code: 'RBL', name: 'RBL Bank', direct: false, nodal: true },
  { code: 'IDC', name: 'IDFC First Bank', direct: false, nodal: true },
]

export const ALL_BSE_BANKS = [...BSE_DIRECT_BANKS, ...BSE_NODAL_BANKS]

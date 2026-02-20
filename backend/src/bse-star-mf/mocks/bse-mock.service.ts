import { Injectable, Logger } from '@nestjs/common'
import { v4 as uuidv4 } from 'uuid'

@Injectable()
export class BseMockService {
  private readonly logger = new Logger(BseMockService.name)

  mockGetPasswordResponse(): string {
    return `100|MOCK_TOKEN_${Date.now()}`
  }

  mockUccRegistrationResponse(clientCode: string) {
    this.logger.log(`[MOCK] UCC Registration for ${clientCode}`)
    return {
      Status: '100',
      Message: 'SUCCESS',
      ClientCode: clientCode,
    }
  }

  mockFatcaUploadResponse() {
    return '100|FATCA uploaded successfully'
  }

  mockCkycUploadResponse() {
    return '100|CKYC uploaded successfully'
  }

  mockMandateRegistrationResponse() {
    const mandateId = `M${Date.now()}`
    return `100|Mandate registered successfully|${mandateId}`
  }

  mockMandateStatusResponse(mandateId: string) {
    return {
      MandateId: mandateId,
      Status: 'APPROVED',
      UMRN: `UMRN${Date.now()}`,
    }
  }

  mockEMandateAuthUrl(mandateId: string) {
    return {
      Status: '100',
      AuthURL: `https://mock-emandate.example.com/auth?id=${mandateId}`,
    }
  }

  mockOrderEntryResponse(transCode: string) {
    const orderNumber = `${Date.now()}`
    this.logger.log(`[MOCK] Order entry: ${transCode}, order #${orderNumber}`)
    return `100|Order placed successfully|${orderNumber}`
  }

  mockSipRegistrationResponse() {
    const regNo = `SIP${Date.now()}`
    return `100|SIP registered successfully|${regNo}`
  }

  mockXsipRegistrationResponse() {
    const regNo = `XSIP${Date.now()}`
    return `100|XSIP registered successfully|${regNo}`
  }

  mockStpRegistrationResponse() {
    return {
      Status: '100',
      Message: 'STP registered successfully',
      RegistrationNo: `STP${Date.now()}`,
    }
  }

  mockSwpRegistrationResponse() {
    return `100|SWP registered successfully|SWP${Date.now()}`
  }

  mockPaymentResponse(orderId: string) {
    return {
      Status: '100',
      Message: 'Payment initiated',
      RedirectURL: `https://mock-payment.example.com/pay?order=${orderId}`,
      TransactionRef: `PAY${Date.now()}`,
    }
  }

  mockOrderStatusResponse() {
    return {
      Status: '100',
      Orders: [
        {
          OrderNumber: '123456',
          Status: 'ALLOTTED',
          AllottedUnits: '100.5000',
          AllottedNav: '45.2300',
          AllottedAmount: '4545.62',
        },
      ],
    }
  }

  mockAllotmentStatementResponse() {
    return {
      Status: '100',
      Allotments: [],
    }
  }

  mockChildOrderDetailsResponse() {
    return {
      Status: '100',
      ChildOrders: [],
    }
  }

  mockSchemeMasterData() {
    return [
      {
        SchemeCode: 'INF-GR-DP',
        SchemeName: 'Test Growth Direct Plan',
        ISIN: 'INF000000001',
        AMCCode: 'TEST',
        PurchaseAllowed: 'Y',
        RedemptionAllowed: 'Y',
        SIPAllowed: 'Y',
        MinPurchaseAmt: '5000',
        MinSIPAmt: '500',
      },
    ]
  }
}

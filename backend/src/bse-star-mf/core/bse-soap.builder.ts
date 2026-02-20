import { Injectable } from '@nestjs/common'

@Injectable()
export class BseSoapBuilder {
  buildEnvelope(action: string, body: string): string {
    return `<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
  xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    ${body}
  </soap12:Body>
</soap12:Envelope>`
  }

  buildGetPasswordBody(
    userId: string,
    memberId: string,
    password: string,
    passKey: string,
  ): string {
    return `<getPassword xmlns="http://bsestarmf.in/">
      <UserId>${this.escapeXml(userId)}</UserId>
      <MemberId>${this.escapeXml(memberId)}</MemberId>
      <Password>${this.escapeXml(password)}</Password>
      <PassKey>${this.escapeXml(passKey)}</PassKey>
    </getPassword>`
  }

  buildOrderEntryBody(passKey: string, params: string): string {
    return `<orderEntryParam xmlns="http://bsestarmf.in/">
      <TransactionCode>${this.escapeXml(passKey)}</TransactionCode>
      <OrderVal>${this.escapeXml(params)}</OrderVal>
    </orderEntryParam>`
  }

  buildSipOrderEntryBody(passKey: string, params: string): string {
    return `<sipOrderEntryParam xmlns="http://bsestarmf.in/">
      <TransactionCode>${this.escapeXml(passKey)}</TransactionCode>
      <OrderVal>${this.escapeXml(params)}</OrderVal>
    </sipOrderEntryParam>`
  }

  buildXsipOrderEntryBody(passKey: string, params: string): string {
    return `<xsipOrderEntryParam xmlns="http://bsestarmf.in/">
      <TransactionCode>${this.escapeXml(passKey)}</TransactionCode>
      <OrderVal>${this.escapeXml(params)}</OrderVal>
    </xsipOrderEntryParam>`
  }

  buildSwitchOrderEntryBody(passKey: string, params: string): string {
    return `<switchOrderEntryParam xmlns="http://bsestarmf.in/">
      <TransactionCode>${this.escapeXml(passKey)}</TransactionCode>
      <OrderVal>${this.escapeXml(params)}</OrderVal>
    </switchOrderEntryParam>`
  }

  buildSpreadOrderEntryBody(passKey: string, params: string): string {
    return `<spreadOrderEntryParam xmlns="http://bsestarmf.in/">
      <TransactionCode>${this.escapeXml(passKey)}</TransactionCode>
      <OrderVal>${this.escapeXml(params)}</OrderVal>
    </spreadOrderEntryParam>`
  }

  buildAdditionalServicesBody(
    flag: string,
    userId: string,
    memberId: string,
    passKey: string,
    params: string,
  ): string {
    return `<GenerateResponse xmlns="http://bsestarmf.in/">
      <Flag>${this.escapeXml(flag)}</Flag>
      <UserId>${this.escapeXml(userId)}</UserId>
      <MemberId>${this.escapeXml(memberId)}</MemberId>
      <Password>${this.escapeXml(passKey)}</Password>
      <Param>${this.escapeXml(params)}</Param>
    </GenerateResponse>`
  }

  /**
   * Build pipe-separated parameter string from key-value pairs
   * BSE expects fields in specific order, separated by pipes
   */
  buildPipeParams(fields: (string | number | undefined | null)[]): string {
    return fields.map((f) => (f != null ? String(f) : '')).join('|')
  }

  private escapeXml(str: string): string {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;')
  }
}

import { Injectable, BadRequestException } from '@nestjs/common';

export interface ParsedBrokerageRow {
  amcName: string;
  schemeCategory: string;
  schemeName: string;
  folioNo: string;
  amount: number;
  transactionType: string;
  brokerageAmount: number;
}

export type BrokerageSourceType = 'CAMS' | 'KFINTECH' | 'MANUAL';

@Injectable()
export class CommissionsParser {
  /**
   * Detect CSV source format and parse rows.
   * CAMS CSVs typically have "AMC Name" column, KFintech uses "Fund House"
   */
  parse(csvContent: string): { source: BrokerageSourceType; rows: ParsedBrokerageRow[] } {
    const lines = csvContent.split('\n').map(l => l.trim()).filter(Boolean);
    if (lines.length < 2) {
      throw new BadRequestException('CSV file is empty or has no data rows');
    }

    const header = lines[0].toLowerCase();
    const source = this.detectSource(header);
    const columns = this.parseCSVLine(lines[0]);
    const colMap = this.buildColumnMap(columns, source);

    const rows: ParsedBrokerageRow[] = [];
    for (let i = 1; i < lines.length; i++) {
      const cells = this.parseCSVLine(lines[i]);
      if (cells.length < 3) continue; // skip malformed rows

      try {
        rows.push({
          amcName: (cells[colMap.amcName] || '').trim(),
          schemeCategory: (cells[colMap.schemeCategory] || '').trim(),
          schemeName: (cells[colMap.schemeName] || '').trim(),
          folioNo: (cells[colMap.folioNo] || '').trim(),
          amount: this.parseNumber(cells[colMap.amount]),
          transactionType: (cells[colMap.transactionType] || '').trim(),
          brokerageAmount: this.parseNumber(cells[colMap.brokerageAmount]),
        });
      } catch {
        // skip unparseable rows
      }
    }

    return { source, rows };
  }

  private detectSource(headerLine: string): BrokerageSourceType {
    if (headerLine.includes('amc name') || headerLine.includes('amc_name')) {
      return 'CAMS';
    }
    if (headerLine.includes('fund house') || headerLine.includes('fund_house')) {
      return 'KFINTECH';
    }
    return 'MANUAL';
  }

  private buildColumnMap(columns: string[], source: BrokerageSourceType) {
    const lower = columns.map(c => c.toLowerCase().trim());

    if (source === 'CAMS') {
      return {
        amcName: this.findCol(lower, ['amc name', 'amc_name', 'amc']),
        schemeCategory: this.findCol(lower, ['scheme category', 'category', 'scheme_category']),
        schemeName: this.findCol(lower, ['scheme name', 'scheme_name', 'scheme']),
        folioNo: this.findCol(lower, ['folio no', 'folio_no', 'folio number', 'folio']),
        amount: this.findCol(lower, ['amount', 'transaction amount', 'txn amount']),
        transactionType: this.findCol(lower, ['transaction type', 'txn type', 'type']),
        brokerageAmount: this.findCol(lower, ['brokerage', 'commission', 'brokerage amount', 'trail']),
      };
    }

    // KFintech format
    return {
      amcName: this.findCol(lower, ['fund house', 'fund_house', 'amc']),
      schemeCategory: this.findCol(lower, ['scheme category', 'category', 'scheme_category', 'asset class']),
      schemeName: this.findCol(lower, ['scheme name', 'scheme_name', 'scheme']),
      folioNo: this.findCol(lower, ['folio no', 'folio_no', 'folio', 'folio number']),
      amount: this.findCol(lower, ['amount', 'transaction amount', 'txn_amount']),
      transactionType: this.findCol(lower, ['transaction type', 'txn_type', 'type']),
      brokerageAmount: this.findCol(lower, ['brokerage', 'commission', 'brokerage_amount', 'trail commission']),
    };
  }

  private findCol(headers: string[], candidates: string[]): number {
    for (const c of candidates) {
      const idx = headers.indexOf(c);
      if (idx >= 0) return idx;
    }
    return 0; // fallback to first column
  }

  private parseNumber(val: string | undefined): number {
    if (!val) return 0;
    const cleaned = val.replace(/[^0-9.\-]/g, '');
    return parseFloat(cleaned) || 0;
  }

  private parseCSVLine(line: string): string[] {
    const result: string[] = [];
    let current = '';
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
      const ch = line[i];
      if (ch === '"') {
        inQuotes = !inQuotes;
      } else if (ch === ',' && !inQuotes) {
        result.push(current);
        current = '';
      } else {
        current += ch;
      }
    }
    result.push(current);
    return result;
  }
}

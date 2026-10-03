import { GuardianReport, StructuredCheckIn } from '../../models/Wellbeing';
import { ApiError, BackendClient, invalidResponse } from './BackendClient';

// Wire shapes from backend/README.md. Fields are optional because the payload is checked before use.
interface ReportDto {
  id?: string;
  period?: string | null;
  structured?: StructuredCheckIn | null;
  summary?: string | null;
  source?: string;
  createdAt?: string;
}

interface ReportListDto {
  items?: ReportDto[];
}

export class ReportBody {
  period: string;
  structured: StructuredCheckIn;
  summary: string;
  source: string;

  constructor(period: string, structured: StructuredCheckIn, summary: string, source: string) {
    this.period = period;
    this.structured = structured;
    this.summary = summary;
    this.source = source;
  }
}

function toReport(dto: ReportDto): GuardianReport | undefined {
  const createdAt = typeof dto.createdAt === 'string' ? Date.parse(dto.createdAt) : NaN;
  if (typeof dto.id !== 'string' || isNaN(createdAt)) {
    return undefined;
  }
  const facts = dto.structured !== null && typeof dto.structured === 'object' ? dto.structured as StructuredCheckIn :
    new StructuredCheckIn();
  if (!Array.isArray(facts.concerns)) {
    facts.concerns = [];
  }
  return new GuardianReport(dto.id, createdAt, typeof dto.period === 'string' ? dto.period : '',
    typeof dto.summary === 'string' ? dto.summary : '', typeof dto.source === 'string' ? dto.source : '', facts);
}

// Wellbeing report endpoints: the senior submits and withdraws, the guardian lists.
export class ReportsApi {
  private readonly client: BackendClient;

  constructor(client: BackendClient) {
    this.client = client;
  }

  // Returns the backend id of the stored report.
  async submit(seniorId: string, body: ReportBody): Promise<string> {
    const stored = await this.client.post<ReportDto>(`/v1/seniors/${encodeURIComponent(seniorId)}/reports`, body);
    if (typeof stored.id !== 'string') {
      throw invalidResponse('report');
    }
    return stored.id;
  }

  // Newest first; `before` pages to older reports.
  async list(seniorId: string, before: Date | undefined, limit: number): Promise<GuardianReport[]> {
    const query = before === undefined ? `limit=${limit}` :
      `limit=${limit}&before=${encodeURIComponent(before.toISOString())}`;
    const list = await this.client.get<ReportListDto>(`/v1/seniors/${encodeURIComponent(seniorId)}/reports?${query}`);
    if (!Array.isArray(list.items)) {
      throw invalidResponse('report list');
    }
    const reports: GuardianReport[] = [];
    (list.items as ReportDto[]).forEach((dto: ReportDto) => {
      const report = toReport(dto);
      if (report !== undefined) {
        reports.push(report);
      }
    });
    return reports;
  }

  // Already withdrawn (HTTP 404) counts as success: the end state is the same.
  async withdraw(seniorId: string, reportId: string): Promise<void> {
    try {
      await this.client.delete(
        `/v1/seniors/${encodeURIComponent(seniorId)}/reports/${encodeURIComponent(reportId)}`);
    } catch (err) {
      if (!(err instanceof ApiError && err.status === 404)) {
        throw err as Error;
      }
    }
  }
}

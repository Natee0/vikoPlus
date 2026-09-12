import { ChangeDetectorRef, Component } from '@angular/core';

import {
  QueueFailureRow,
  QueueSummary,
  SuperAdminApi,
} from '../../core/super-admin-api';
import { GroupTableComponent } from '../../shared/group-table/group-table';
import { GroupRow, ProductMetricRow, StatCard } from '../../shared/super-admin-data';

@Component({
  selector: 'sa-overview',
  imports: [GroupTableComponent],
  templateUrl: './overview.html',
})
export class OverviewPage {
  constructor(
    private readonly api: SuperAdminApi,
    private readonly changeDetector: ChangeDetectorRef,
  ) {}

  stats: StatCard[] = [];
  groups: GroupRow[] = [];
  productMetrics: ProductMetricRow[] = [];
  queues: QueueSummary[] = [];
  selectedQueueName = '';
  failedJobs: QueueFailureRow[] = [];
  failedJobCount = 0;
  errorMessage = '';
  queueMessage = '';
  isLoading = false;
  isQueueLoading = false;
  queueActionKey = '';

  async ngOnInit(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const [stats, groups, productMetrics, queues] = await Promise.all([
        this.api.overviewStats(),
        this.api.groups(),
        this.api.productMetrics(),
        this.api.queues(),
      ]);
      this.stats = stats;
      this.groups = groups.slice(0, 5);
      this.productMetrics = productMetrics;
      this.queues = queues;
      this.selectedQueueName = this.selectedQueueName || queues[0]?.name || '';
      await this.loadFailedJobs();
    } catch {
      this.errorMessage = 'Could not load live platform data.';
      this.stats = [];
      this.groups = [];
      this.productMetrics = [];
      this.queues = [];
      this.failedJobs = [];
    } finally {
      this.isLoading = false;
      this.changeDetector.detectChanges();
    }
  }

  queueStatusClass(queue: QueueSummary): 'active' | 'pending' | 'flagged' {
    if (queue.counts.failed > 0 || queue.paused) {
      return 'flagged';
    }
    if (queue.counts.waiting > 0 || queue.counts.active > 0 || queue.counts.delayed > 0) {
      return 'pending';
    }
    return 'active';
  }

  queueStatusLabel(queue: QueueSummary): string {
    if (queue.paused) return 'Paused';
    if (queue.counts.failed > 0) return 'Needs attention';
    if (queue.counts.waiting > 0 || queue.counts.active > 0 || queue.counts.delayed > 0) {
      return 'Processing';
    }
    return 'Healthy';
  }

  async refreshQueues(): Promise<void> {
    this.queueMessage = '';
    this.isQueueLoading = true;
    try {
      this.queues = await this.api.queues();
      if (!this.selectedQueueName) {
        this.selectedQueueName = this.queues[0]?.name || '';
      }
      await this.loadFailedJobs();
      this.queueMessage = 'Queue data refreshed.';
    } catch {
      this.queueMessage = 'Could not refresh queue data.';
    } finally {
      this.isQueueLoading = false;
      this.changeDetector.detectChanges();
    }
  }

  async selectQueue(queueName: string): Promise<void> {
    if (this.selectedQueueName === queueName) return;
    this.selectedQueueName = queueName;
    await this.loadFailedJobs();
  }

  async retryJob(job: QueueFailureRow): Promise<void> {
    if (!this.selectedQueueName) return;
    const actionKey = `retry:${job.id}`;
    this.queueActionKey = actionKey;
    this.queueMessage = '';
    try {
      await this.api.retryFailedQueueJob(this.selectedQueueName, job.id);
      this.queueMessage = `Queued retry for ${job.name}.`;
      await this.refreshQueues();
    } catch {
      this.queueMessage = 'Could not retry the failed job.';
    } finally {
      if (this.queueActionKey === actionKey) {
        this.queueActionKey = '';
      }
      this.changeDetector.detectChanges();
    }
  }

  async cleanFailedJobs(): Promise<void> {
    if (!this.selectedQueueName) return;
    this.queueActionKey = 'clean';
    this.queueMessage = '';
    try {
      await this.api.cleanFailedQueueJobs(this.selectedQueueName);
      this.queueMessage = 'Old failed jobs were cleaned.';
      await this.refreshQueues();
    } catch {
      this.queueMessage = 'Could not clean failed jobs.';
    } finally {
      if (this.queueActionKey === 'clean') {
        this.queueActionKey = '';
      }
      this.changeDetector.detectChanges();
    }
  }

  formatQueueDate(value: string | null): string {
    if (!value) return 'Not available';
    return new Intl.DateTimeFormat('en-TZ', {
      month: 'short',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    }).format(new Date(value));
  }

  private async loadFailedJobs(): Promise<void> {
    if (!this.selectedQueueName) {
      this.failedJobs = [];
      this.failedJobCount = 0;
      return;
    }
    const result = await this.api.failedQueueJobs(this.selectedQueueName, 0, 49);
    this.failedJobs = result.jobs;
    this.failedJobCount = result.failedCount;
  }
}

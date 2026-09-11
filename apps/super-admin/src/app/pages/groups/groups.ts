import { ChangeDetectorRef, Component } from '@angular/core';

import { SuperAdminApi, UpsertGroupInput } from '../../core/super-admin-api';
import {
  AdminDialogComponent,
  AdminDialogConfig,
} from '../../shared/admin-dialog/admin-dialog';
import { GroupTableComponent } from '../../shared/group-table/group-table';
import { GroupRow, StatCard } from '../../shared/super-admin-data';

@Component({
  selector: 'sa-groups',
  imports: [GroupTableComponent, AdminDialogComponent],
  templateUrl: './groups.html',
})
export class GroupsPage {
  constructor(
    private readonly api: SuperAdminApi,
    private readonly changeDetector: ChangeDetectorRef,
  ) {}

  stats: StatCard[] = [];
  groups: GroupRow[] = [];
  errorMessage = '';
  isLoading = false;
  isSaving = false;
  dialogOpen = false;
  dialogConfig: AdminDialogConfig | null = null;
  private pendingDialog:
    | { kind: 'create' }
    | { kind: 'edit'; group: GroupRow }
    | { kind: 'delete'; group: GroupRow }
    | null = null;

  async ngOnInit(): Promise<void> {
    await this.loadGroups();
  }

  async loadGroups(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const [stats, groups] = await Promise.all([
        this.api.groupStats(),
        this.api.groups(),
      ]);
      this.stats = stats;
      this.groups = groups;
    } catch {
      this.errorMessage = 'Could not load live groups.';
      this.stats = [];
      this.groups = [];
    } finally {
      this.isLoading = false;
      this.changeDetector.detectChanges();
    }
  }

  createGroup(): void {
    this.pendingDialog = { kind: 'create' };
    this.dialogConfig = this.groupDialogConfig();
    this.dialogOpen = true;
  }

  editGroup(group: GroupRow): void {
    if (!group.id) return;
    this.pendingDialog = { kind: 'edit', group };
    this.dialogConfig = this.groupDialogConfig(group);
    this.dialogOpen = true;
  }

  deleteGroup(group: GroupRow): void {
    if (!group.id) return;
    this.pendingDialog = { kind: 'delete', group };
    this.dialogConfig = {
      title: `Delete ${group.name}?`,
      message:
        'This will permanently delete the group and all members, payments, loans, expenses, reminders, subscriptions, and history. This cannot be undone.',
      confirmLabel: 'Delete everything',
      danger: true,
    };
    this.dialogOpen = true;
  }

  closeDialog(): void {
    if (this.isSaving) return;
    this.dialogOpen = false;
    this.dialogConfig = null;
    this.pendingDialog = null;
  }

  async confirmDialog(values: Record<string, string | number | boolean>): Promise<void> {
    const pending = this.pendingDialog;
    if (!pending) return;
    if (pending.kind === 'delete') {
      await this.runGroupAction(() => this.api.deleteGroup(pending.group.id!));
      this.closeDialog();
      return;
    }
    const input: UpsertGroupInput = {
      name: String(values['name'] ?? '').trim(),
      type: String(values['type'] ?? '').trim() || undefined,
      location: String(values['location'] ?? '').trim() || undefined,
      currency: String(values['currency'] ?? 'TZS').trim().toUpperCase() || 'TZS',
    };
    if (!input.name) return;
    await this.runGroupAction(() =>
      pending.kind === 'create'
        ? this.api.createGroup(input)
        : this.api.updateGroup(pending.group.id!, input),
    );
    this.closeDialog();
  }

  private async runGroupAction(action: () => Promise<void>): Promise<void> {
    if (this.isSaving) return;
    this.isSaving = true;
    this.errorMessage = '';
    try {
      await action();
      await this.loadGroups();
    } catch (error) {
      this.errorMessage =
        error instanceof Error ? error.message : 'Could not save group changes.';
    } finally {
      this.isSaving = false;
      this.changeDetector.detectChanges();
    }
  }

  private groupDialogConfig(group?: GroupRow): AdminDialogConfig {
    return {
      title: group ? 'Edit group' : 'Add group',
      confirmLabel: group ? 'Save changes' : 'Create group',
      fields: [
        { name: 'name', label: 'Group name', value: group?.name ?? '', required: true },
        { name: 'type', label: 'Group type', value: group?.type ?? '' },
        { name: 'location', label: 'Location', value: group?.country ?? '' },
        { name: 'currency', label: 'Currency', value: group?.currency ?? 'TZS', required: true },
      ],
    };
  }
}

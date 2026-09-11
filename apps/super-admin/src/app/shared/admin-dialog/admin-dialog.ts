import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';

export type AdminDialogField = {
  name: string;
  label: string;
  type?: 'text' | 'number' | 'select' | 'textarea';
  value?: string | number | boolean | null;
  options?: Array<{ label: string; value: string | number | boolean }>;
  required?: boolean;
};

export type AdminDialogConfig = {
  title: string;
  message?: string;
  confirmLabel?: string;
  cancelLabel?: string;
  danger?: boolean;
  fields?: AdminDialogField[];
};

@Component({
  selector: 'sa-admin-dialog',
  imports: [FormsModule],
  templateUrl: './admin-dialog.html',
})
export class AdminDialogComponent {
  @Input() open = false;
  @Input() config: AdminDialogConfig | null = null;
  @Input() isBusy = false;
  @Output() cancelled = new EventEmitter<void>();
  @Output() confirmed = new EventEmitter<Record<string, string | number | boolean>>();

  values: Record<string, string | number | boolean> = {};
  private signature = '';

  get fields(): AdminDialogField[] {
    return this.config?.fields ?? [];
  }

  get canConfirm(): boolean {
    return this.fields.every((field) => {
      if (!field.required) return true;
      const value = this.values[field.name];
      return value !== undefined && value !== null && String(value).trim().length > 0;
    });
  }

  ngOnChanges(): void {
    const nextSignature = JSON.stringify(this.config ?? {});
    if (nextSignature === this.signature) return;
    this.signature = nextSignature;
    this.values = {};
    for (const field of this.fields) {
      this.values[field.name] = field.value ?? '';
    }
  }

  cancel(): void {
    if (this.isBusy) return;
    this.cancelled.emit();
  }

  confirm(): void {
    if (this.isBusy || !this.canConfirm) return;
    this.confirmed.emit({ ...this.values });
  }
}

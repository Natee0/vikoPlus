import { Component, Input } from '@angular/core';

import { GroupRow } from '../super-admin-data';

@Component({
  selector: 'sa-group-table',
  imports: [],
  templateUrl: './group-table.html',
})
export class GroupTableComponent {
  @Input() rows: GroupRow[] = [];
}

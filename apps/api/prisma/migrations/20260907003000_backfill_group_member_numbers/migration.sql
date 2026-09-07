WITH existing_max AS (
  SELECT
    "groupId",
    COALESCE(
      MAX(
        CASE
          WHEN "memberNumber" ~ '^MBR-[0-9]{6}$'
          THEN SUBSTRING("memberNumber" FROM 5)::integer
          ELSE 0
        END
      ),
      0
    ) AS max_number
  FROM "GroupMember"
  GROUP BY "groupId"
),
numbered_members AS (
  SELECT
    member."id",
    COALESCE(existing_max.max_number, 0) +
    ROW_NUMBER() OVER (
      PARTITION BY member."groupId"
      ORDER BY member."createdAt", member."id"
    ) AS sequence_number
  FROM "GroupMember" AS member
  LEFT JOIN existing_max ON existing_max."groupId" = member."groupId"
  WHERE member."memberNumber" IS NULL
)
UPDATE "GroupMember" AS member
SET "memberNumber" = 'MBR-' || LPAD(numbered.sequence_number::text, 6, '0')
FROM numbered_members AS numbered
WHERE member."id" = numbered."id";

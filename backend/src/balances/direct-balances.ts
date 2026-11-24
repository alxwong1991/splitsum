import { InternalServerErrorException } from '@nestjs/common';
import { Prisma } from '../generated/prisma/client';

interface BalanceRow {
  fromId: string;
  fromName: string;
  fromArchived: boolean;
  toId: string;
  toName: string;
  toArchived: boolean;
  amount: string;
}

export async function calculateDirectBalances(
  db: Prisma.TransactionClient,
  groupId: string,
) {
  const rows = await db.$queryRaw<BalanceRow[]>`
    SELECT debtor."id" AS "fromId", debtor."name" AS "fromName",
           debtor."archived" AS "fromArchived",
           creditor."id" AS "toId", creditor."name" AS "toName",
           creditor."archived" AS "toArchived",
           SUM(movement.amount)::text AS "amount"
    FROM (
      SELECT share."participantId" AS debtor, bill."payerId" AS creditor,
             share."amountCents"::bigint AS amount
      FROM "BillShare" share
      JOIN "Bill" bill ON bill."id" = share."billId" AND bill."groupId" = share."groupId"
      WHERE bill."groupId" = ${groupId}::uuid AND share."participantId" <> bill."payerId"
      UNION ALL
      SELECT settlement."fromParticipantId", settlement."toParticipantId",
             -settlement."amountCents"::bigint
      FROM "Settlement" settlement
      WHERE settlement."groupId" = ${groupId}::uuid
    ) movement
    JOIN "Participant" debtor ON debtor."id" = movement.debtor AND debtor."groupId" = ${groupId}::uuid
    JOIN "Participant" creditor ON creditor."id" = movement.creditor AND creditor."groupId" = ${groupId}::uuid
    GROUP BY debtor."id", creditor."id"
    HAVING SUM(movement.amount) <> 0
    ORDER BY debtor."position", creditor."position"
  `;

  return rows.map((row) => {
    const amount = BigInt(row.amount);
    if (amount < 0n || amount > BigInt(Number.MAX_SAFE_INTEGER)) {
      throw new InternalServerErrorException(
        'A balance is invalid or exceeds the supported range.',
      );
    }
    return {
      fromParticipant: {
        id: row.fromId,
        name: row.fromName,
        archived: row.fromArchived,
      },
      toParticipant: {
        id: row.toId,
        name: row.toName,
        archived: row.toArchived,
      },
      amountCents: Number(amount),
    };
  });
}

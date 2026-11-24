CREATE TABLE "Bill" (
    "id" UUID NOT NULL,
    "groupId" UUID NOT NULL,
    "payerId" UUID NOT NULL,
    "description" VARCHAR(120) NOT NULL,
    "billDate" DATE NOT NULL,
    "totalCents" INTEGER NOT NULL,
    "currency" CHAR(3) NOT NULL DEFAULT 'HKD',
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Bill_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Bill_totalCents_check" CHECK ("totalCents" > 0),
    CONSTRAINT "Bill_currency_check" CHECK ("currency" = 'HKD')
);

CREATE TABLE "BillShare" (
    "billId" UUID NOT NULL,
    "groupId" UUID NOT NULL,
    "participantId" UUID NOT NULL,
    "amountCents" INTEGER NOT NULL,
    CONSTRAINT "BillShare_pkey" PRIMARY KEY ("billId","participantId"),
    CONSTRAINT "BillShare_amountCents_check" CHECK ("amountCents" >= 0)
);

CREATE TABLE "IdempotencyRequest" (
    "id" UUID NOT NULL,
    "ownerId" UUID NOT NULL,
    "operation" VARCHAR(40) NOT NULL,
    "key" VARCHAR(128) NOT NULL,
    "payload" TEXT NOT NULL,
    "billId" UUID NOT NULL,
    CONSTRAINT "IdempotencyRequest_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "Bill_groupId_billDate_createdAt_idx" ON "Bill"("groupId", "billDate", "createdAt");
CREATE UNIQUE INDEX "Bill_groupId_id_key" ON "Bill"("groupId", "id");
CREATE UNIQUE INDEX "IdempotencyRequest_billId_key" ON "IdempotencyRequest"("billId");
CREATE UNIQUE INDEX "IdempotencyRequest_ownerId_operation_key_key" ON "IdempotencyRequest"("ownerId", "operation", "key");

ALTER TABLE "Bill" ADD CONSTRAINT "Bill_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Bill" ADD CONSTRAINT "Bill_groupId_payerId_fkey" FOREIGN KEY ("groupId", "payerId") REFERENCES "Participant"("groupId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE "BillShare" ADD CONSTRAINT "BillShare_groupId_billId_fkey" FOREIGN KEY ("groupId", "billId") REFERENCES "Bill"("groupId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE "BillShare" ADD CONSTRAINT "BillShare_groupId_participantId_fkey" FOREIGN KEY ("groupId", "participantId") REFERENCES "Participant"("groupId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE "IdempotencyRequest" ADD CONSTRAINT "IdempotencyRequest_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "Account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "IdempotencyRequest" ADD CONSTRAINT "IdempotencyRequest_billId_fkey" FOREIGN KEY ("billId") REFERENCES "Bill"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

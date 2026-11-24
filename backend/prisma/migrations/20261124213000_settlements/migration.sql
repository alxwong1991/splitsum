ALTER TABLE "Group" ADD COLUMN "hasEverHadSettlement" BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE "IdempotencyRequest"
    ADD COLUMN "settlementId" UUID,
    ALTER COLUMN "billId" DROP NOT NULL;

CREATE TABLE "Settlement" (
    "id" UUID NOT NULL,
    "groupId" UUID NOT NULL,
    "fromParticipantId" UUID NOT NULL,
    "toParticipantId" UUID NOT NULL,
    "amountCents" INTEGER NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Settlement_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Settlement_amountCents_check" CHECK ("amountCents" > 0),
    CONSTRAINT "Settlement_distinct_participants_check" CHECK ("fromParticipantId" <> "toParticipantId")
);

ALTER TABLE "IdempotencyRequest" ADD CONSTRAINT "IdempotencyRequest_resource_check"
    CHECK (("billId" IS NOT NULL AND "settlementId" IS NULL) OR ("billId" IS NULL AND "settlementId" IS NOT NULL));

CREATE INDEX "Settlement_groupId_createdAt_idx" ON "Settlement"("groupId", "createdAt");
CREATE UNIQUE INDEX "IdempotencyRequest_settlementId_key" ON "IdempotencyRequest"("settlementId");

ALTER TABLE "IdempotencyRequest" ADD CONSTRAINT "IdempotencyRequest_settlementId_fkey" FOREIGN KEY ("settlementId") REFERENCES "Settlement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Settlement" ADD CONSTRAINT "Settlement_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Settlement" ADD CONSTRAINT "Settlement_groupId_fromParticipantId_fkey" FOREIGN KEY ("groupId", "fromParticipantId") REFERENCES "Participant"("groupId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE "Settlement" ADD CONSTRAINT "Settlement_groupId_toParticipantId_fkey" FOREIGN KEY ("groupId", "toParticipantId") REFERENCES "Participant"("groupId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

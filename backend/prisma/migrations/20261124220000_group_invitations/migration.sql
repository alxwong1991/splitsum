CREATE TYPE "InvitationStatus" AS ENUM ('PENDING', 'ACCEPTED', 'DECLINED', 'CANCELLED');

ALTER TABLE "Participant" ADD COLUMN "accountId" UUID;

CREATE TABLE "GroupInvitation" (
    "id" UUID NOT NULL,
    "groupId" UUID NOT NULL,
    "recipientId" UUID NOT NULL,
    "status" "InvitationStatus" NOT NULL DEFAULT 'PENDING',
    "acceptedParticipantId" UUID,
    "acceptedName" VARCHAR(80),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    CONSTRAINT "GroupInvitation_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "GroupInvitation_accepted_fields_check" CHECK (
      ("status" = 'ACCEPTED' AND "acceptedParticipantId" IS NOT NULL AND "acceptedName" IS NOT NULL)
      OR ("status" <> 'ACCEPTED' AND "acceptedParticipantId" IS NULL AND "acceptedName" IS NULL)
    )
);

CREATE INDEX "GroupInvitation_recipientId_status_idx" ON "GroupInvitation"("recipientId", "status");
CREATE INDEX "GroupInvitation_groupId_recipientId_idx" ON "GroupInvitation"("groupId", "recipientId");
CREATE UNIQUE INDEX "GroupInvitation_groupId_acceptedParticipantId_key" ON "GroupInvitation"("groupId", "acceptedParticipantId");
CREATE UNIQUE INDEX "GroupInvitation_pending_group_recipient_key" ON "GroupInvitation"("groupId", "recipientId") WHERE "status" = 'PENDING';
CREATE UNIQUE INDEX "Participant_groupId_accountId_key" ON "Participant"("groupId", "accountId");

ALTER TABLE "Participant" ADD CONSTRAINT "Participant_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "Account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "GroupInvitation" ADD CONSTRAINT "GroupInvitation_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Group"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "GroupInvitation" ADD CONSTRAINT "GroupInvitation_recipientId_fkey" FOREIGN KEY ("recipientId") REFERENCES "Account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "GroupInvitation" ADD CONSTRAINT "GroupInvitation_groupId_acceptedParticipantId_fkey" FOREIGN KEY ("groupId", "acceptedParticipantId") REFERENCES "Participant"("groupId", "id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AlterTable
ALTER TABLE "Message" ADD COLUMN     "imageUrl" TEXT,
ADD COLUMN     "messageType" TEXT NOT NULL DEFAULT 'text',
ALTER COLUMN "content" DROP NOT NULL;

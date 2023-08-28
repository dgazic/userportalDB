ALTER TABLE dbo.PasswordReset ADD CONSTRAINT FK_PasswordResetUser FOREIGN KEY(UserId)
REFERENCES dbo.[User](Id)

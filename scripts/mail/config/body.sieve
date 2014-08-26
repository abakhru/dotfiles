require ["body", "fileinto"];
if body :raw :contains "MAKE MONEY FAST"
{
       discard;
}
if body :text :contains "project schedule" {
                fileinto "project/schedule";
}

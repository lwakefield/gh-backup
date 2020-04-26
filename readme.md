# gh-backup

All we have here, is a simple script which enumerates your github projects, and syncs them to an S3 Bucket.

The project hasn't been set up for easy distribution, so here is what you need:
- [Crystal 0.34.0](https://crystal-lang.org/install/) - this is what the script is written in
- [rclone](https://rclone.org/) - this is is used to upload the archives to S3
- A *nix-esque system with git - Crystal doesn't yet have great windows support

To run the script, you will need to configure some environment variables:
- `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, `S3_ENDPOINT` and `S3_BUCKET` - these are what they sound like, config used to interact with S3
- `GH_USERNAME` and `GH_TOKEN` these are what they seem.

---

The real magic here, is that we can configure GitHub Actions to automatically run this script, once a week. To do this, clone the repository, configure the secrets to match the environment variables above and let 'er run.

# Note: Remove pom.xml after merge

⚠️ **Manual Action Required**: After merging this PR, please delete `pom.xml` from the main branch as it's no longer needed.

This project has been migrated from Maven to Gradle, but GitHub's API limitations prevent automatic file deletion in this PR.

## Command to run after merge:
```bash
git checkout main
git pull origin main
git rm pom.xml
git commit -m "Remove obsolete pom.xml - now using Gradle exclusively"
git push origin main
```

## Why this file should be removed:
- Project now uses **Gradle** exclusively
- `pom.xml` is outdated (Spring Boot 3.3.2 vs current 3.5.4)
- Having both build files causes confusion
- Gradle provides better performance and modern features

---
*This note will be removed once pom.xml is deleted*

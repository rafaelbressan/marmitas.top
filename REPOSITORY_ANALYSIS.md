# Repository Analysis: marmitas.top

**Analysis Date:** November 7, 2025
**Repository:** rafaelbressan/marmitas.top (fork)

## Executive Summary

This repository is a fork of Christian Kaisermann's project that lists affordable lunch options (marmitas/quentinhas) in Rio de Janeiro and São Paulo, Brazil. The project has been **inactive for over 6 years**, with the last commit made on **May 14, 2019**.

## Project Overview

**Purpose:** A static website showcasing budget-friendly lunch spots (marmitas) in Brazilian cities
**Technology Stack:**
- Build System: Gulp 4.0
- Template Engine: Nunjucks
- CSS: Stylus
- JavaScript: ES6+ (Babel 7 + Rollup)
- Framework: Hyperion (static site workflow by kaisermann)
- Grid System: RolleiFLEX

**Website URL:** https://marmitas.top

## Repository History

### Activity Timeline
- **Total commits:** 25 (all before 2019)
- **Primary development period:** July 2017 - May 2019
- **Last commit:** May 14, 2019 by Edgard Kozlowski
- **Peak activity:** July-August 2017
- **Contributors:**
  - Christian Kaisermann (primary developer)
  - Edgard Kozlowski (secondary contributor)

### Recent Commits (Last 5)
1. `3119709` - Update twitter user (May 14, 2019)
2. `b4a0ee9` - Add dozão (Aug 27, 2018)
3. `f2f27b8` - Re-add favicon.ico (Feb 1, 2018)
4. `f988717` - Remove main.js script tag (Feb 1, 2018)
5. `61d9085` - Exclude build folder from repo (Feb 1, 2018)

## Current Repository State

### Fork Information
- **Original Repository:** kaisermann/hyperion
- **Original Author:** Christian Kaisermann
- **Fork Status:** No upstream remote configured
- **Divergence:** Unknown (no upstream tracking)

### Technical Debt & Concerns

#### 1. Severely Outdated Dependencies
The project uses dependencies from **2018** (7 years old):

**Critical Issues:**
- Node.js version: v9.0.0 (EOL April 2018, **unsupported for 7+ years**)
- Babel 7 beta version: `7.0.0-beta.37` (unstable/pre-release)
- Gulp 4.0 alpha (from 2018)
- ESLint 4.x (current stable is 8.x+)
- Multiple packages with known security vulnerabilities likely present

**Missing Dependencies:**
- `node_modules/` directory not installed
- 3 missing runtime dependencies detected:
  - nib 1.2.0
  - rolleiflex 6.1.2
  - rupture 0.7.1

#### 2. Security Concerns
- Ancient Node.js version with **known security vulnerabilities**
- Outdated build tools and dependencies
- No security updates in 6+ years
- Browser targets include IE 11 and Opera 12 (both discontinued)

#### 3. Browser Compatibility
Current `browserslist` configuration:
```json
"browserslist": [
  "last 2 versions",
  "opera 12",
  "IE 11",
  "Safari >= 8"
]
```
This targets browsers from 2013-2015, which is outdated for modern web development.

#### 4. Build System Status
- Build folder excluded from repo (correct practice)
- No CI/CD configuration detected
- No automated testing setup
- Build scripts require manual execution

### Content Analysis

The project currently lists **15 lunch spots in Rio de Janeiro**, including:
- Price range: R$8.00 - R$16.00 per meal
- Locations span: Centro, Ipanema, Copacabana, Botafogo, Flamengo, Barra, Vila Isabel, Leme
- Includes variety: traditional Brazilian, Chinese, vegetarian/vegan options
- Contains useful details: addresses, coordinates, phone numbers, working hours

**Content Concerns:**
- Pricing data is from 2017-2019 (likely outdated due to inflation)
- Business status unknown (may have closed/relocated during COVID-19 pandemic)
- No updates for 6+ years means information is probably inaccurate
- Phone numbers and addresses should be verified

### No Active Maintenance

**Indicators of abandonment:**
- No commits since 2019
- No dependency updates
- No security patches
- No content updates
- Only 1 branch exists (current working branch)

## Recommendations

### Immediate Actions (High Priority)

1. **Verify Content Accuracy**
   - Contact/visit businesses to confirm they're still operating
   - Update prices to 2025 values
   - Verify addresses, phone numbers, and working hours
   - Remove closed businesses

2. **Check Upstream Status**
   - Add upstream remote: `git remote add upstream https://github.com/kaisermann/hyperion.git`
   - Fetch upstream changes: `git fetch upstream`
   - Check if kaisermann/hyperion has updates
   - Evaluate if upstream changes should be merged

3. **Assess Project Viability**
   - Decide if the project should be revived or archived
   - Determine if the content is still valuable
   - Consider community interest

### Short-term Actions (If Reviving)

4. **Modernize Dependencies**
   - Upgrade to Node.js LTS (v20 or v22)
   - Update all npm packages to latest stable versions
   - Replace beta packages with stable releases
   - Run security audit: `npm audit fix`
   - Update browserslist to remove discontinued browsers

5. **Improve Project Structure**
   - Add `.github/dependabot.yml` for automated dependency updates
   - Configure GitHub Actions for CI/CD
   - Add testing framework
   - Create CONTRIBUTING.md guidelines

6. **Update Documentation**
   - Update README.md with current status
   - Add setup instructions
   - Document deployment process
   - Add screenshots of current site

### Long-term Actions

7. **Consider Architectural Changes**
   - Evaluate modern static site generators (Next.js, Astro, 11ty)
   - Consider migration from Gulp to modern bundlers (Vite, esbuild)
   - Implement a CMS for easier content management
   - Add user submissions feature

8. **Community Engagement**
   - Create issues for crowdsourced updates
   - Add contribution templates
   - Set up discussions for recommendations
   - Create social media presence

## Upstream Repository Status

The original **kaisermann/hyperion** repository is a static website workflow framework. To check its current status:

```bash
git remote add upstream https://github.com/kaisermann/hyperion.git
git fetch upstream
git log upstream/master --oneline -10
```

This will reveal if the upstream has:
- Bug fixes
- Security updates
- New features
- Better documentation

## Risk Assessment

**Current Risk Level:** 🔴 **HIGH**

- **Security Risk:** HIGH - Ancient Node.js with known CVEs
- **Functionality Risk:** MEDIUM - Site may build but dependencies are fragile
- **Content Risk:** HIGH - 6-year-old business information likely inaccurate
- **Maintenance Risk:** HIGH - No active maintainer, abandoned project

## Conclusion

This project represents a time capsule of Rio de Janeiro's lunch scene from 2017-2019. While the concept is valuable, the implementation is severely outdated and potentially insecure.

**Decision Required:**
- **Option A:** Complete modernization overhaul (significant effort)
- **Option B:** Archive repository with historical context
- **Option C:** Fork to new framework and migrate content only

Without updates, this repository should be considered **archived/unmaintained** and marked as such to prevent users from relying on outdated information.

---

*This analysis was generated on November 7, 2025, examining a repository last updated May 14, 2019.*

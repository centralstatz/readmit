<div class="rrp-home">

<section class="rrp-hero" aria-labelledby="rrp-home-title">
<div class="rrp-hero-copy">
<p class="rrp-kicker">READMISSION RISK POOL · ANALYTICAL PLATFORM</p>
<img class="rrp-hero-logo" src="reference/figures/rrp-platform-dark.svg" alt="Readmission Risk Pool platform logo">
<h1 id="rrp-home-title">Understand how remaining readmission risk changes after discharge.</h1>
<p class="rrp-lead">Readmission Risk Pool (RRP) connects an organization's data and risk provider to repeated, point-in-time assessments. The <code>readmit</code> R package supplies the shared analytical workflow, retained history, and a project-owned application.</p>
<div class="rrp-actions">
<a class="rrp-button rrp-button-primary" href="articles/getting-started.html">Get started <span aria-hidden="true">→</span></a>
<a class="rrp-button rrp-button-secondary" href="articles/implementing-rrp.html">Explore the implementation guide</a>
</div>
</div>
<div class="rrp-hero-aside" aria-label="RRP workflow: map sources, assess risk, retain history, explore products">
<p class="rrp-aside-label">A REPEATABLE WORKFLOW</p>
<div class="rrp-workflow-step"><span>01</span><strong>Map</strong><small>organization-owned sources</small></div>
<div class="rrp-workflow-step"><span>02</span><strong>Assess</strong><small>risk at chosen times</small></div>
<div class="rrp-workflow-step"><span>03</span><strong>Retain</strong><small>outcomes across runs</small></div>
<div class="rrp-workflow-step"><span>04</span><strong>Explore</strong><small>products in the app</small></div>
</div>
</section>

<section class="rrp-section rrp-motivation" aria-labelledby="rrp-why">
<div class="rrp-section-heading">
<p class="rrp-kicker">THE ANALYTICAL QUESTION</p>
<h2 id="rrp-why">One prediction at discharge cannot describe a changing risk pool.</h2>
</div>
<div class="rrp-motivation-grid">
<p>As follow-up time passes and new information becomes available, the set of eligible discharge episodes can change. A later assessment asks about the <strong>remaining probability of a first hospital readmission strictly after that time and through 30 elapsed days after the original discharge</strong>. Each assessment keeps the original endpoint; it does not restart the 30-day window.</p>
<p>RRP applies shared eligibility rules to the episodes an organization supplies, records accepted estimates and other dispositions at each chosen time, and derives current-risk, trajectory, and operational-summary products. Its trajectories are recorded assessments, not continuous predictions between runs.</p>
</div>
</section>

<section class="rrp-section" aria-labelledby="rrp-capabilities">
<div class="rrp-section-heading">
<p class="rrp-kicker">WHAT THE PLATFORM ENABLES</p>
<h2 id="rrp-capabilities">From local inputs to an inspectable risk pool.</h2>
<p>The organization controls clinical sources, mapping, the risk provider, and how results are evaluated and used. <code>readmit</code> provides the shared structure around those choices.</p>
</div>
<div class="rrp-capability-grid">
<article class="rrp-capability"><span class="rrp-card-index">01 / CONNECT</span><h3>Own the implementation</h3><p>Start with an ordinary project directory containing editable source-mapping and risk-provider scripts, configuration, branding, and its own Shiny app.</p></article>
<article class="rrp-capability"><span class="rrp-card-index">02 / ASSESS</span><h3>Reassess at chosen times</h3><p>Apply discharge-anchored eligibility and point-in-time event availability before requesting risk for eligible episodes.</p></article>
<article class="rrp-capability"><span class="rrp-card-index">03 / RETAIN</span><h3>Keep the full history</h3><p>Retain completed runs, including accepted estimates, provider failures, and ineligible episodes, so earlier results remain inspectable.</p></article>
<article class="rrp-capability"><span class="rrp-card-index">04 / EXPLORE</span><h3>See the pool and its trajectories</h3><p>Refresh CSV products from history and explore current remaining risk, recorded episode trajectories, and operational scope in the project app.</p></article>
</div>
</section>

<section class="rrp-section rrp-app-section" aria-labelledby="rrp-app-preview">
<div class="rrp-section-heading">
<p class="rrp-kicker">THE PROJECT-OWNED APPLICATION</p>
<h2 id="rrp-app-preview">A working view of the current pool and recorded risk.</h2>
<p>The existing application lists eligible discharge episodes and their current estimates. Selecting an episode reveals its accepted assessments across runs.</p>
</div>
<figure class="rrp-app-figure">
<a href="rrp-app-preview.jpg" aria-label="Open the full-size simulated RRP application screenshot"><img src="rrp-app-preview.jpg" alt="Simulated RRP project application showing eligible discharge episodes with current-risk bars, one selected episode, and its recorded risk trajectory" loading="lazy"></a>
<figcaption>Actual RRP Shiny application with simulated data. The risk values and episode IDs are illustrative; no patient records are shown. Open the image for a full-size view.</figcaption>
</figure>
</section>

<section class="rrp-section rrp-start-section" aria-labelledby="rrp-start">
<div class="rrp-section-heading">
<p class="rrp-kicker">START WITH READMIT</p>
<h2 id="rrp-start">Build an RRP project around your data and model.</h2>
<p>Install the current development package from GitHub, then use the short walkthrough or the complete simulated-hospital guide.</p>
</div>
<div class="rrp-start-grid">
<div class="rrp-install-card"><span class="rrp-card-index">DEVELOPMENT INSTALL</span><pre><code>install.packages("remotes")
remotes::install_github("centralstatz/readmit")</code></pre><p>Project authors supply source mapping and a risk provider. RRP does not include a clinically validated model.</p></div>
<div class="rrp-doc-links">
<a href="articles/getting-started.html"><strong>Getting started</strong><span>A short, installed vignette for the project workflow.</span></a>
<a href="articles/implementing-rrp.html"><strong>Implementation guide</strong><span>A full simulated-hospital walkthrough with source mapping and a demonstration model.</span></a>
<a href="reference/index.html"><strong>Function reference</strong><span>Package operations, arguments, and examples.</span></a>
<a href="https://github.com/centralstatz/readmit"><strong>GitHub repository</strong><span>Source code, issues, and the current development version.</span></a>
</div>
</div>
</section>

<aside class="rrp-release-note" aria-label="Development status">
<span class="rrp-status-dot" aria-hidden="true"></span>
<div><strong>Current status: RRP development version 0.0.1.9000.</strong> The older <a href="https://cran.r-project.org/package=readmit">CRAN <code>readmit</code> 0.0.1</a> has substantially different functionality and does not install this RRP implementation. The intended RRP 1.0.0 release has not yet been submitted to CRAN.</div>
</aside>

</div>

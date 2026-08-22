import {
  ArrowRight,
  Check,
  Download,
  FileSpreadsheet,
  Lock,
  Monitor,
  Settings2,
  ShieldCheck,
} from 'lucide-react'
import './App.css'

const engineDownload = '/tools/StratificationOptimizationEngine.exe'
const engineHash =
  'C3DCAD167D89CF6093C001B13513B7D45C96B9B2F5DB812341475A3518288561'

function App() {
  return (
    <main>
      <nav className="nav" aria-label="Primary navigation">
        <a className="brand" href="/">
          <span className="brand-mark" aria-hidden="true">
            PH
          </span>
          <span>
            <strong>Psych Hub</strong>
            <small>Research Operations</small>
          </span>
        </a>
        <span className="status">
          <span className="status-dot" aria-hidden="true" />
          Engine available
        </span>
      </nav>

      <section className="hero">
        <div className="hero-copy">
          <p className="eyebrow">
            <Settings2 size={16} aria-hidden="true" />
            Optimization workspace
          </p>
          <h1>
            Build balanced samples.
            <span>Deliver with confidence.</span>
          </h1>
          <p className="lede">
            Prepare stratification inputs, run constrained optimization, and
            produce final TEID and quality-assurance workbooks from one
            purpose-built Windows tool.
          </p>
          <div className="hero-actions">
            <a className="button button-primary" href={engineDownload} download>
              <Download size={18} aria-hidden="true" />
              Download for Windows
            </a>
            <a className="text-link" href="#workflow">
              See how it works
              <ArrowRight size={17} aria-hidden="true" />
            </a>
          </div>
          <p className="download-meta">
            Windows 10/11 · 75.6 MB · Standalone application
          </p>
        </div>

        <aside className="engine-card" aria-label="Engine summary">
          <div className="engine-card-header">
            <div className="app-icon" aria-hidden="true">
              <Settings2 size={28} />
            </div>
            <div>
              <p>Desktop tool</p>
              <h2>Stratification Optimization Engine</h2>
            </div>
          </div>
          <div className="engine-window" aria-hidden="true">
            <div className="window-bar">
              <span />
              <span />
              <span />
            </div>
            <div className="window-tabs">
              <strong>Part A · Prepare</strong>
              <strong>Part B · Optimize</strong>
            </div>
            <div className="window-fields">
              <span />
              <span />
              <span />
              <div className="progress">
                <i />
              </div>
            </div>
          </div>
          <div className="privacy-note">
            <Lock size={17} aria-hidden="true" />
            <span>
              <strong>Runs locally</strong>
              Your research files stay on your computer.
            </span>
          </div>
        </aside>
      </section>

      <section className="workflow" id="workflow">
        <div className="section-heading">
          <p className="eyebrow">Two-part workflow</p>
          <h2>From source data to final deliverables</h2>
          <p>
            The engine guides you through preparation and optimization while
            keeping each stage transparent and repeatable.
          </p>
        </div>

        <div className="step-grid">
          <article className="step-card">
            <span className="step-number">01</span>
            <div className="step-icon">
              <FileSpreadsheet size={24} aria-hidden="true" />
            </div>
            <p className="step-label">Part A</p>
            <h3>Prepare inputs</h3>
            <p>
              Clean the master sample, build the available pool, and prepare
              exact sex-balance inputs.
            </p>
            <ul>
              <li>
                <Check size={15} aria-hidden="true" />
                Master sample workbook
              </li>
              <li>
                <Check size={15} aria-hidden="true" />
                Scored SAS data
              </li>
              <li>
                <Check size={15} aria-hidden="true" />
                Demographic and OSEP targets
              </li>
            </ul>
          </article>

          <article className="step-card step-card-accent">
            <span className="step-number">02</span>
            <div className="step-icon">
              <Settings2 size={24} aria-hidden="true" />
            </div>
            <p className="step-label">Part B</p>
            <h3>Optimize and export</h3>
            <p>
              Run the constraint solver and generate the complete delivery
              package.
            </p>
            <ul>
              <li>
                <Check size={15} aria-hidden="true" />
                Final TEID workbook
              </li>
              <li>
                <Check size={15} aria-hidden="true" />
                Swap and target outputs
              </li>
              <li>
                <Check size={15} aria-hidden="true" />
                Quality-assurance workbooks
              </li>
            </ul>
          </article>
        </div>
      </section>

      <section className="install">
        <div className="install-copy">
          <Monitor size={25} aria-hidden="true" />
          <div>
            <h2>Ready to run your optimization?</h2>
            <p>
              Download the standalone Windows app. No Python installation is
              required.
            </p>
          </div>
        </div>
        <a className="button button-light" href={engineDownload} download>
          <Download size={18} aria-hidden="true" />
          Download engine
        </a>
      </section>

      <footer>
        <span>Psych Hub · Stratification tools</span>
        <details>
          <summary>
            <ShieldCheck size={15} aria-hidden="true" />
            Verify download
          </summary>
          <code>SHA-256: {engineHash}</code>
        </details>
      </footer>
    </main>
  )
}

export default App

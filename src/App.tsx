import { useMemo, useState } from 'react'

type Role = 'Resident' | 'Administrator' | 'Management'
type Page = 'Overview' | 'Usage' | 'Bills' | 'Alerts' | 'Readings' | 'Reports' | 'Settings'

const navByRole: Record<Role, Page[]> = {
  Resident: ['Overview', 'Usage', 'Bills', 'Alerts', 'Settings'],
  Administrator: ['Overview', 'Readings', 'Bills', 'Alerts', 'Reports', 'Settings'],
  Management: ['Overview', 'Usage', 'Reports', 'Settings'],
}

const points = [34, 42, 38, 56, 49, 69, 61, 78, 71, 91, 82, 73]
const pointLabels = ['1', '3', '5', '7', '9', '11', '13', '15', '17', '19', '21', '23']
const alerts = [
  { type: 'High usage', title: 'Usage is higher than usual', detail: 'House 14 · Agbowo · 2 hours ago', tone: 'amber' },
  { type: 'No data', title: 'No recent reading received', detail: 'Meter UI-AG-008 · 4 hours ago', tone: 'blue' },
  { type: 'Review', title: 'Reading needs a quick check', detail: 'House 22 · Ajibode · Yesterday', tone: 'rose' },
]

function Icon({ name }: { name: string }) {
  const paths: Record<string, string> = {
    Overview: 'M3 10.5 12 3l9 7.5V21h-6v-6H9v6H3z',
    Usage: 'M4 19V5m0 14h16M7 15l3-4 3 2 5-7',
    Bills: 'M6 3h12v18l-3-2-3 2-3-2-3 2zM9 8h6M9 12h6M9 16h3',
    Alerts: 'M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4',
    Readings: 'M4 5h16M4 12h16M4 19h16M8 3v4m8-4v4m-8 3v4m8-4v4m-8 3v4m8-4v4',
    Reports: 'M5 3h14v18H5zM8 8h8M8 12h8M8 16h5',
    Settings: 'M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8zm0-5v2m0 14v2m9-9h-2M5 12H3m15.36-6.36-1.42 1.42M7.06 16.94l-1.42 1.42m12.72 0-1.42-1.42M7.06 7.06 5.64 5.64',
  }
  return <svg className="nav-icon" viewBox="0 0 24 24" aria-hidden="true"><path d={paths[name] || paths.Overview} /></svg>
}

function TrendChart() {
  const coords = points.map((v, i) => `${30 + i * 61},${176 - v * 1.45}`).join(' ')
  const area = `30,180 ${coords} 701,180`
  return (
    <div className="chart-wrap">
      <svg className="chart" viewBox="0 0 720 210" role="img" aria-label="Hourly electricity use trend, peaking in the evening">
        <defs><linearGradient id="fill" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stopColor="#d5aa42" stopOpacity=".24"/><stop offset="100%" stopColor="#d5aa42" stopOpacity="0"/></linearGradient></defs>
        {[34, 78, 122, 166].map(y => <line key={y} x1="30" x2="702" y1={y} y2={y} className="grid-line" />)}
        <polygon points={area} fill="url(#fill)" />
        <polyline points={coords} className="chart-line" />
        {points.map((v, i) => <circle key={i} cx={30 + i * 61} cy={176 - v * 1.45} r="3.4" className="chart-dot" />)}
      </svg>
      <div className="chart-x">{pointLabels.map((label, i) => <span key={label}>{i % 2 === 0 ? `${label}:00` : ''}</span>)}</div>
      <div className="chart-unit">kWh</div>
    </div>
  )
}

function App() {
  const [role, setRole] = useState<Role>('Resident')
  const [page, setPage] = useState<Page>('Overview')
  const [period, setPeriod] = useState('Today')
  const [notice, setNotice] = useState('')
  const nav = useMemo(() => navByRole[role], [role])

  function changeRole(next: Role) {
    setRole(next)
    const allowed = navByRole[next]
    if (!allowed.includes(page)) setPage('Overview')
  }

  function action(message: string) {
    setNotice(message)
    window.setTimeout(() => setNotice(''), 2800)
  }

  const title = page === 'Overview' ? (role === 'Resident' ? 'Good morning, Amina' : role === 'Administrator' ? 'Works overview' : 'Energy overview') : page

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-mark" aria-hidden="true"><span>UI</span><i /></div>
          <div><strong>ECMS</strong><small>Energy monitoring</small></div>
          <button className="mobile-close" aria-label="Close menu" onClick={() => document.body.classList.remove('menu-open')}>×</button>
        </div>
        <div className="workspace-label">WORKSPACE</div>
        <nav aria-label="Main navigation">
          {nav.map(item => <button key={item} className={`nav-item ${page === item ? 'active' : ''}`} onClick={() => setPage(item)}><Icon name={item}/><span>{item}</span>{item === 'Alerts' && <b className="nav-count">3</b>}</button>)}
        </nav>
        <div className="sidebar-bottom">
          <div className="campus-card"><span className="campus-symbol">⌂</span><div><b>University of Ibadan</b><small>Staff quarters</small></div></div>
          <button className="profile"><span className="avatar">AO</span><span className="profile-copy"><b>{role === 'Resident' ? 'Amina Okafor' : role === 'Administrator' ? 'Works Admin' : 'Energy Manager'}</b><small>{role}</small></span><span className="dots">•••</span></button>
        </div>
      </aside>

      <main className="main-area">
        <header className="topbar">
          <button className="menu-trigger" aria-label="Open menu" onClick={() => document.body.classList.add('menu-open')}>☰</button>
          <div className="breadcrumb">ECMS <span>/</span> {page}</div>
          <div className="top-actions">
            <label className="role-picker"><span>View as</span><select aria-label="Preview role" value={role} onChange={e => changeRole(e.target.value as Role)}><option>Resident</option><option>Administrator</option><option>Management</option></select></label>
            <button className="icon-button" aria-label="Notifications" onClick={() => setPage('Alerts')}><Icon name="Alerts"/><i /></button>
            <span className="top-avatar">AO</span>
          </div>
        </header>

        <div className="content">
          <div className="demo-banner"><span className="demo-dot"/> DEMO DATA <span className="banner-separator">·</span> Values are simulated for this prototype.</div>
          <section className="page-heading">
            <div><p className="eyebrow">{role === 'Resident' ? 'AGBOWO · HOUSE 08' : role === 'Administrator' ? 'OPERATIONS' : 'QUARTERS SUMMARY'}</p><h1>{title}</h1><p className="subtitle">{role === 'Resident' ? 'Here’s how your home is using electricity.' : role === 'Administrator' ? 'Monitor readings, meters, and resident support.' : 'A clear view of electricity use across the quarters.'}</p></div>
            <div className="heading-actions"><button className="button button-secondary" onClick={() => action('Your report is being prepared.')}>↓ <span>Export</span></button><button className="button button-primary" onClick={() => role === 'Administrator' ? setPage('Readings') : action('Your latest usage is up to date.')}>{role === 'Administrator' ? '+ Add reading' : '↻ Refresh'}</button></div>
          </section>

          {page === 'Overview' || page === 'Usage' ? <>
            <section className="metrics-grid" aria-label="Consumption summary">
              <article className="metric-card primary-metric"><div className="metric-top"><span>{role === 'Management' ? 'Total use today' : 'Electricity used today'}</span><span className="metric-icon gold-icon">ϟ</span></div><div className="metric-value">{role === 'Management' ? '428.6' : '8.42'} <small>kWh</small></div><div className="metric-foot"><span className="trend-up">↗ 12.4%</span><span>vs. previous day</span></div></article>
              <article className="metric-card"><div className="metric-top"><span>Estimated cost</span><span className="metric-icon">₦</span></div><div className="metric-value">{role === 'Management' ? '₦ 59,480' : '₦ 1,168'}<small></small></div><div className="metric-foot"><span>Based on current tariff</span></div></article>
              <article className="metric-card"><div className="metric-top"><span>Month to date</span><span className="metric-icon">▤</span></div><div className="metric-value">{role === 'Management' ? '8,246' : '186.3'} <small>kWh</small></div><div className="metric-foot"><span className="trend-down">↘ 4.8%</span><span>vs. last month</span></div></article>
              <article className="metric-card"><div className="metric-top"><span>{role === 'Resident' ? 'Next bill' : 'Open alerts'}</span><span className="metric-icon">{role === 'Resident' ? '◷' : '!'}</span></div><div className="metric-value">{role === 'Resident' ? '30 Nov' : '03'}<small>{role === 'Resident' ? ' · in 12 days' : ' active'}</small></div><div className="metric-foot"><span>{role === 'Resident' ? 'Current billing period' : 'Across active meters'}</span></div></article>
            </section>

            <section className="main-grid">
              <article className="panel usage-panel">
                <div className="panel-header"><div><div className="panel-title">Energy consumption</div><div className="panel-subtitle">Track how usage changes through the day</div></div><select className="select-control" value={period} onChange={e => setPeriod(e.target.value)} aria-label="Chart period"><option>Today</option><option>This week</option><option>This month</option></select></div>
                <div className="chart-legend"><span><i className="legend-dot"/> Energy used</span><span className="legend-note">Peak: 7:00–9:00 PM</span></div>
                <TrendChart />
                <div className="chart-summary"><div><small>AVERAGE DAILY USE</small><b>6.21 <em>kWh</em></b></div><div><small>HIGHEST USE</small><b>9.14 <em>kWh · Tue</em></b></div><div><small>DATA UPDATED</small><b>2 min <em>ago</em></b></div></div>
              </article>
              <article className="panel alerts-panel"><div className="panel-header"><div><div className="panel-title">Needs your attention</div><div className="panel-subtitle">Recent activity and alerts</div></div><button className="text-link" onClick={() => setPage('Alerts')}>See all <span>→</span></button></div>
                <div className="alert-list">{alerts.map((alert, i) => <button className="alert-item" key={alert.title} onClick={() => action(`${alert.type}: ${alert.title}`)}><span className={`alert-symbol ${alert.tone}`}>{i === 0 ? '↗' : i === 1 ? '◷' : '!'}</span><span className="alert-copy"><span className="alert-type">{alert.type}</span><b>{alert.title}</b><small>{alert.detail}</small></span><span className="chevron">›</span></button>)}</div>
                <button className="all-alerts" onClick={() => setPage('Alerts')}>View all alerts <span>→</span></button>
              </article>
            </section>

            <section className="bottom-grid">
              <article className="panel reading-panel"><div className="panel-header"><div><div className="panel-title">Latest readings</div><div className="panel-subtitle">Most recent meter updates</div></div><button className="text-link" onClick={() => setPage('Readings')}>All readings <span>→</span></button></div><div className="table-scroll"><table><thead><tr><th>DATE & TIME</th><th>USAGE</th><th>SOURCE</th><th>STATUS</th></tr></thead><tbody><tr><td><b>Today, 2:15 PM</b><small>18 Nov 2026</small></td><td>0.38 kWh</td><td><span className="source-tag"><i/> Smart meter</span></td><td><span className="status-pill valid">✓ Valid</span></td></tr><tr><td><b>Today, 2:00 PM</b><small>18 Nov 2026</small></td><td>0.42 kWh</td><td><span className="source-tag manual"><i/> Manual</span></td><td><span className="status-pill valid">✓ Valid</span></td></tr><tr><td><b>Today, 1:45 PM</b><small>18 Nov 2026</small></td><td>0.35 kWh</td><td><span className="source-tag"><i/> Smart meter</span></td><td><span className="status-pill review">! Review</span></td></tr></tbody></table></div></article>
              <article className="panel bill-panel"><div className="panel-header"><div><div className="panel-title">Current bill</div><div className="panel-subtitle">November 2026 · in progress</div></div><span className="bill-icon">₦</span></div><div className="bill-amount">₦ 18,630 <span>estimated</span></div><div className="bill-meter"><div><span>Consumption this period</span><b>186.3 kWh</b></div><div className="meter-track"><i style={{ width: '68%' }}/></div><div className="bill-caption"><span>68% of last month</span><span>12 days left</span></div></div><button className="button button-secondary full-button" onClick={() => setPage('Bills')}>View bill details <span>→</span></button></article>
            </section>
          </> : <section className="page-placeholder panel"><div className="placeholder-icon"><Icon name={page}/></div><p className="eyebrow">{role.toUpperCase()} WORKSPACE</p><h2>{page}</h2><p>This area is part of the MVP plan. The overview is connected to simulated data; this workflow will be built next.</p><button className="button button-primary" onClick={() => setPage('Overview')}>Back to overview</button></section>}

          <footer className="page-footer"><span>ECMS · University of Ibadan</span><span>Data shown is simulated <i/> Prototype v0.1</span></footer>
        </div>
      </main>
      {notice && <div className="toast" role="status">✓ &nbsp;{notice}</div>}
    </div>
  )
}

export default App

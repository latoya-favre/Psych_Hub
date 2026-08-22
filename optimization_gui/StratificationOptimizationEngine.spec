# -*- mode: python ; coding: utf-8 -*-
from pathlib import Path
from PyInstaller.utils.hooks import collect_dynamic_libs

here = Path(SPECPATH)
project = here.parent

a = Analysis(
    ['app.py'],
    pathex=[str(here)],
    binaries=collect_dynamic_libs('ortools'),
    datas=[
        (str(project / 'scripts' / 'Optimization Engine Part A.py'), 'engines'),
        (str(project / 'scripts' / 'Optimization Engine Part B.py'), 'engines'),
    ],
    hiddenimports=[
        'pandas', 'openpyxl', 'pyreadstat',
        'ortools.sat.python.cp_model',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['torch', 'torchvision', 'scipy', 'pyarrow', 'streamlit', 'matplotlib'],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)
exe = EXE(
    pyz, a.scripts, a.binaries, a.datas, [],
    name='StratificationOptimizationEngine',
    debug=False, bootloader_ignore_signals=False, strip=False, upx=True,
    console=False, disable_windowed_traceback=False,
)

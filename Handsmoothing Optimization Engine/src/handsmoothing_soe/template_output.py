from __future__ import annotations

from pathlib import Path, PurePosixPath
import re
from typing import Sequence
from xml.etree import ElementTree
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

from .model import CurveSolution


_MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
_REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
_PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"


def _worksheet_part(archive: ZipFile, sheet_name: str) -> str:
    workbook_root = ElementTree.fromstring(archive.read("xl/workbook.xml"))
    sheet = workbook_root.find(f".//{{{_MAIN_NS}}}sheet[@name='{sheet_name}']")
    if sheet is None:
        raise ValueError(f"Template workbook does not contain sheet {sheet_name!r}")
    relationship_id = sheet.attrib[f"{{{_REL_NS}}}id"]

    rels_root = ElementTree.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
    relationship = rels_root.find(f".//{{{_PKG_REL_NS}}}Relationship[@Id='{relationship_id}']")
    if relationship is None:
        raise ValueError(f"Could not resolve worksheet relationship {relationship_id!r}")
    target = relationship.attrib["Target"].replace("\\", "/")
    if target.startswith("/"):
        return target.lstrip("/")
    return str(PurePosixPath("xl") / target)


def _replace_numeric_cell(xml: str, cell_reference: str, value: int) -> str:
    pattern = re.compile(
        rf'(<c\b(?=[^>]*\br="{re.escape(cell_reference)}")[^>]*>.*?<v>)(.*?)(</v>)',
        flags=re.DOTALL,
    )
    updated, count = pattern.subn(rf"\g<1>{int(value)}\g<3>", xml, count=1)
    if count != 1:
        raise ValueError(f"Could not locate one numeric value cell for {cell_reference}")
    return updated


def _force_recalculation(xml: str) -> str:
    calc_pattern = re.compile(r"<calcPr\b[^>]*/>")
    match = calc_pattern.search(xml)
    if match is None:
        return xml
    calc = match.group(0)
    attributes = {
        "calcMode": "auto",
        "fullCalcOnLoad": "1",
        "forceFullCalc": "1",
    }
    for name, value in attributes.items():
        if re.search(rf'\b{name}="[^"]*"', calc):
            calc = re.sub(rf'\b{name}="[^"]*"', f'{name}="{value}"', calc)
        else:
            calc = calc[:-2] + f' {name}="{value}"/>'
    return xml[: match.start()] + calc + xml[match.end() :]


def write_template_workbook(
    template_path: str | Path,
    output_path: str | Path,
    solutions: Sequence[CurveSolution],
    *,
    sheet_name: str = "Hdsmth",
) -> Path:
    """Copy a template XLSX and replace only its optimized score values.

    The score grid starts at column B, row 2. Its row and group counts are
    inferred from the solutions. Workbook styles, formulas, conditional
    formatting, and other package parts are copied without reconstruction.
    """
    source = Path(template_path)
    destination = Path(output_path)
    if not source.is_file():
        raise FileNotFoundError(source)
    if not solutions:
        raise ValueError("At least one curve solution is required")
    row_count = len(solutions[0].scores or [])
    for solution in solutions:
        if solution.scores is None:
            raise ValueError(f"Cannot create workbook: {solution.name} has no feasible solution")
        if len(solution.scores) != row_count:
            raise ValueError(
                f"Expected {row_count} scores for {solution.name}, received {len(solution.scores)}"
            )

    destination.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(source, "r") as source_zip:
        sheet_part = _worksheet_part(source_zip, sheet_name)
        sheet_xml = source_zip.read(sheet_part).decode("utf-8")
        for group_index, solution in enumerate(solutions, start=2):
            column = chr(ord("A") + group_index - 1)
            for row_index, score in enumerate(solution.scores or [], start=2):
                sheet_xml = _replace_numeric_cell(sheet_xml, f"{column}{row_index}", score)

        workbook_xml = _force_recalculation(source_zip.read("xl/workbook.xml").decode("utf-8"))
        with ZipFile(destination, "w", compression=ZIP_DEFLATED, compresslevel=6) as output_zip:
            for source_info in source_zip.infolist():
                payload = source_zip.read(source_info.filename)
                if source_info.filename == sheet_part:
                    payload = sheet_xml.encode("utf-8")
                elif source_info.filename == "xl/workbook.xml":
                    payload = workbook_xml.encode("utf-8")
                target_info = ZipInfo(source_info.filename, date_time=source_info.date_time)
                target_info.compress_type = source_info.compress_type
                target_info.comment = source_info.comment
                target_info.extra = source_info.extra
                target_info.internal_attr = source_info.internal_attr
                target_info.external_attr = source_info.external_attr
                target_info.create_system = source_info.create_system
                target_info.flag_bits = source_info.flag_bits
                output_zip.writestr(target_info, payload)
    return destination

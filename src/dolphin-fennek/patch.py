#!/usr/bin/python3
"""Fennek OS changes to Files (Dolphin), applied to Fedora's source during the image build (build.sh):

  1. No separator lines between groups (This PC: Folders / Frequent folders / Storage drives).
  2. Groups fold: a click on a group's name hides its items (▸), another click shows them again (▾).
     Folded groups stay folded while Files runs (by name, so "Frequent folders" stays folded everywhere).
     How: the layout gives a folded group's items no height (the group's name keeps its place), and their
     widgets paint nothing; the name is drawn by the first item's widget, which stays.

Each change looks for an exact piece of Dolphin's code; if a new Dolphin version changed it, the build stops here
with the piece named, instead of shipping a half-patched Files.

  patch.py DOLPHIN_SOURCE_DIR
"""
import pathlib, sys

src = pathlib.Path(sys.argv[1]) / "src" / "kitemviews"


def patch(rel, old, new, count=1):
    p = src / rel
    t = p.read_text(encoding="utf-8")
    assert t.count(old) == count, f"{rel}: expected {count} of: {old[:80]!r}"
    p.write_text(t.replace(old, new), encoding="utf-8")


# Shared: the folded groups, by name.
(src / "fennekcollapse.h").write_text("""// Fennek OS: groups folded by a click on their name (see src/dolphin-fennek/patch.py).
#pragma once
#include <QSet>
#include <QString>
inline QSet<QString> &fennekCollapsedGroups()
{
    static QSet<QString> groups;
    return groups;
}
""", encoding="utf-8")

# 1. No separator lines; the group's name with a fold arrow.
patch("kstandarditemlistgroupheader.cpp", '#include "kstandarditemlistgroupheader.h"\n',
      '#include "kstandarditemlistgroupheader.h"\n#include "fennekcollapse.h"\n')
patch("kstandarditemlistgroupheader.cpp",
      "void KStandardItemListGroupHeader::paintSeparator(QPainter *painter, const QColor &color)\n{\n",
      "void KStandardItemListGroupHeader::paintSeparator(QPainter *painter, const QColor &color)\n{\n"
      "    if (painter) {\n        return; // Fennek OS: no separator lines between groups\n    }\n")
patch("kstandarditemlistgroupheader.cpp", "        painter->drawText(roleBounds, 0, m_text);\n",
      "        const bool folded = fennekCollapsedGroups().contains(data().toString());\n"
      "        painter->drawText(roleBounds, 0, QString(QChar(folded ? 0x25B8 : 0x25BE)) + QStringLiteral(\"  \") + m_text);\n")

# 2a. Layout: a folded group's items get no height.
patch("private/kitemlistviewlayouter.h", "    QVector<ItemInfo> m_itemInfos;\n",
      "    QVector<ItemInfo> m_itemInfos;\n    QSet<int> m_fennekHiddenItems; // Fennek OS: items of folded groups\n")
patch("private/kitemlistviewlayouter.h", "    bool isFirstGroupItem(int itemIndex) const;\n",
      "    bool isFirstGroupItem(int itemIndex) const;\n"
      "    bool fennekIsHidden(int itemIndex) const\n    {\n        return m_fennekHiddenItems.contains(itemIndex);\n    }\n")
patch("private/kitemlistviewlayouter.cpp", '#include "kitemlistviewlayouter.h"\n',
      '#include "kitemlistviewlayouter.h"\n#include "kitemviews/fennekcollapse.h"\n')
patch("private/kitemlistviewlayouter.cpp", "    m_itemInfos.resize(itemCount);\n",
      "    m_itemInfos.resize(itemCount);\n"
      "    m_fennekHiddenItems.clear();\n"
      "    QSet<int> fennekFoldedStarts;\n"
      "    if (grouped && !horizontalScrolling) {\n"
      "        const auto groups = m_model->groups();\n"
      "        for (const auto &g : groups) {\n"
      "            if (fennekCollapsedGroups().contains(g.second.toString())) {\n"
      "                fennekFoldedStarts.insert(g.first);\n"
      "            }\n"
      "        }\n"
      "    }\n")
patch("private/kitemlistviewlayouter.cpp", "        m_rowOffsets[row] = y;\n",
      "        m_rowOffsets[row] = y;\n"
      "        if (fennekFoldedStarts.contains(index)) { // Fennek OS: a folded group: its name only\n"
      "            do {\n"
      "                m_itemInfos[index].column = 0;\n"
      "                m_itemInfos[index].row = row;\n"
      "                m_fennekHiddenItems.insert(index);\n"
      "                ++index;\n"
      "            } while (index < itemCount && !m_groupItemIndexes.contains(index));\n"
      "            ++row;\n"
      "            continue;\n"
      "        }\n")
patch("private/kitemlistviewlayouter.cpp",
      "        sizeHint.rwidth() = m_itemSize.width();\n    }\n",
      "        sizeHint.rwidth() = m_itemSize.width();\n    }\n"
      "    if (m_fennekHiddenItems.contains(index)) {\n        sizeHint.rheight() = 0; // Fennek OS: in a folded group\n    }\n")

# 2b. View: their widgets paint nothing (the group's name, a child of the first one, still shows).
patch("kitemlistview.cpp", "        Q_ASSERT(widget->index() == i);\n        widget->setVisible(true);\n",
      "        Q_ASSERT(widget->index() == i);\n        widget->setVisible(true);\n"
      "        widget->setFlag(QGraphicsItem::ItemHasNoContents, m_layouter->fennekIsHidden(i)); // Fennek OS: folded group\n")

# 2c. A click on a group's name folds / unfolds it.
patch("kitemlistcontroller.cpp", '#include "kitemlistcontroller.h"\n',
      '#include "kitemlistcontroller.h"\n#include "fennekcollapse.h"\n#include "kitemlistgroupheader.h"\n')
patch("kitemlistcontroller.cpp", """    const QPointF pressedMousePos = transform.map(event->pos());
    m_pressedIndex = m_view->itemAt(pressedMousePos);
""", """    const QPointF pressedMousePos = transform.map(event->pos());
    m_pressedIndex = m_view->itemAt(pressedMousePos);

    // Fennek OS: a click on a group's name (not on an item) folds / unfolds the group.
    if (!m_pressedIndex.has_value() && m_model && m_view->m_grouped && event->button() == Qt::LeftButton
        && m_view->scene() && !m_view->scene()->views().isEmpty()) {
        const int first = indexCloseToMousePressedPosition();
        if (first >= 0) {
            const auto groups = m_model->groups();
            for (const auto &g : groups) {
                if (g.first == first) {
                    const QString name = g.second.toString();
                    if (!fennekCollapsedGroups().remove(name)) {
                        fennekCollapsedGroups().insert(name);
                    }
                    m_view->updateVisibleGroupHeaders();
                    m_view->doLayout(KItemListView::NoAnimation);
                    for (KItemListGroupHeader *header : std::as_const(m_view->m_visibleGroups)) {
                        header->update();
                    }
                    return true;
                }
            }
        }
    }
""")
print("dolphin: Fennek changes applied")

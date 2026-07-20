<script setup>
import { computed, reactive, ref } from 'vue'

const menuItems = [
  '01 全站建筑物（钢结构）', '02 220kV 设备基础及支架', '03 110kV 设备基础及支架',
  '04 主变设备支架', '05 主变基础及油坑', '06 主变构架', '07 主变和电容器防火墙',
  '08 独立避雷针', '09 消防水池', '10 与站址相关工程量', '11 总平面工程量',
  '12 临设工程量', '13 站内外给排水工程量', '14 全站消防配置', '15 采暖通风'
]

const activeMenu = ref('11 总平面工程量')
const projectName = ref('新建220kV 半户内变电站工程')

const rows = reactive([
  { no: '1.1', category: '站址总用地面积', name: '', unit: 'hm²', value: '0.9255', remark: '13.8825亩' },
  { no: '1.2', category: '围墙内占地面积', name: '', unit: 'hm²', value: '0.7943', remark: '11.9145亩' },
  { no: '1.3', category: '进站道路占地面积', name: '', unit: 'hm²', value: '0.0225', remark: '0.3375亩' },
  { no: '1.4', category: '边坡挡墙占地面积', name: '', unit: 'hm²', value: '0.1087', remark: '1.6305亩' },
  { no: '2.1', category: '围墙', name: '围墙长度', unit: 'm', value: '357', remark: '装配式围墙，一体化墙板，2.5m高' },
  { no: '2.2', category: '围墙', name: '单个基础量（含基础连梁）：2.3方', unit: '个', value: '0', remark: '埋设-1.5m，基底尺寸2×2，C30钢筋混凝土（仅考虑部分区域）' },
  { no: '2.3', category: '围墙', name: '钢柱：HW200×200×8×12镀锌钢柱（防腐处理）+4M×16螺栓，160kg/个', unit: '个', value: '122', remark: '' },
  { no: '2.4', category: '围墙', name: '基础地脚螺栓4M20螺栓', unit: 'kg', value: '1300', remark: '' },
  { no: '2.5', category: '围墙', name: '钢柱：HW200×100×5.5×8镀锌钢柱（防腐处理）+4M×16螺栓，160kg/个', unit: '个', value: '50', remark: '考虑变形缝' },
  { no: '3.1', category: '道路', name: '站内道路面积', unit: 'm²', value: '1750', remark: '沥青混凝土道路，做法：从上至下为100厚沥青混凝土（B级70号石油沥青）；200厚C30混凝土面层（内掺抗裂纤维）' },
  { no: '3.2', category: '道路', name: '新建进站道路面积', unit: 'm²', value: '280', remark: '180厚6%水泥稳定碎石基层；200厚级配碎石底基层；500厚三七灰土垫层（压实度≥95%）' },
  { no: '3.3', category: '道路', name: '临时进站道路面积', unit: 'm²', value: '0', remark: '沥青混凝土路面：做法同上' },
  { no: '3.4', category: '道路', name: '花岗岩路缘石', unit: 'm', value: '800', remark: '1000×300×120花岗岩路缘石' }
])

const query = ref('')
const collapsedCategories = ref(new Set())

const filteredRows = computed(() => {
  const keyword = query.value.trim().toLowerCase()
  if (!keyword) return rows
  return rows.filter((row) => Object.values(row).some((value) => String(value).toLowerCase().includes(keyword)))
})

const categoryCounts = computed(() => filteredRows.value.reduce((counts, row) => {
  counts[row.category] = (counts[row.category] || 0) + 1
  return counts
}, {}))

const tableRows = computed(() => {
  const seen = {}
  return filteredRows.value.reduce((result, row) => {
    const total = categoryCounts.value[row.category] || 1
    const collapsed = collapsedCategories.value.has(row.category)
    const seenCount = seen[row.category] || 0
    if (collapsed && seenCount > 0) return result

    seen[row.category] = seenCount + 1
    result.push({
      ...row,
      showCategory: seenCount === 0,
      rowspan: collapsed ? 1 : total,
      expandable: total > 1,
      collapsed
    })
    return result
  }, [])
})

function toggleCategory(category) {
  const next = new Set(collapsedCategories.value)
  if (next.has(category)) next.delete(category)
  else next.add(category)
  collapsedCategories.value = next
}
</script>

<template>
  <div class="app-shell">
    <div class="menu-bar">文件</div>

    <aside class="sidebar">
      <div class="brand-card">
        <strong>工程提资</strong>
        <span>220kV 半户内变电站</span>
        <small>以业务数据组织，不依赖 Excel 模板</small>
      </div>

      <nav class="tree-nav" aria-label="工程量目录">
        <p class="tree-label">土建</p>
        <button
          v-for="item in menuItems"
          :key="item"
          class="tree-item"
          :class="{ active: activeMenu === item }"
          @click="activeMenu = item"
        >
          <span class="tree-arrow">›</span>{{ item }}
        </button>
      </nav>
    </aside>

    <main class="workspace">
      <header class="page-heading">
        <h1>{{ activeMenu }}</h1>
        <p>总平面工程量。</p>
      </header>

      <section class="project-card">
        <label for="project-name">工程名称</label>
        <input id="project-name" v-model="projectName" />
        <p>适用于当前已梳理完成的 220kV 半户内变电站提资目录。</p>
      </section>

      <section class="table-card">
        <div class="table-heading">
          <h2>11.1 总平面工程量</h2>
          <input v-model="query" aria-label="搜索工程量" placeholder="搜索项目、规格或备注" />
        </div>

        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>序号</th>
                <th>项目 / 规格</th>
                <th>工程内容</th>
                <th>单位</th>
                <th>工程量（E列填写）</th>
                <th>备注 / 技术说明</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in tableRows" :key="row.no">
                <td>{{ row.no }}</td>
                <td v-if="row.showCategory" :rowspan="row.rowspan" class="category-cell">
                  <button v-if="row.expandable" class="category-toggle" :aria-label="`${row.collapsed ? '展开' : '收起'}${row.category}`" @click="toggleCategory(row.category)">
                    {{ row.collapsed ? '+' : '−' }}
                  </button>
                  <span>{{ row.category }}</span>
                </td>
                <td>{{ row.name || '—' }}</td>
                <td>{{ row.unit }}</td>
                <td><input v-model="row.value" class="quantity-input" aria-label="填写工程量" /></td>
                <td>{{ row.remark }}</td>
              </tr>
              <tr v-if="tableRows.length === 0"><td colspan="6" class="empty-state">未找到匹配的工程量条目</td></tr>
            </tbody>
          </table>
        </div>
      </section>
    </main>
  </div>
</template>

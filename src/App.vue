<script setup>
import { computed, reactive, ref } from 'vue'

const sections = [
  { title: '接入系统', icon: '◎', items: ['评审资料采集', '项目评审'] },
  { title: '基建可研', icon: '▣', items: ['评审资料采集', '项目评审', '项目收口'] },
  { title: '基建初设', icon: '◈', active: true, items: ['评审资料采集', '项目评审', '项目收口'] },
  { title: '基建施工图', icon: '▤', items: [] },
  { title: '众兴院评审项目', icon: '◫', items: ['送审版资料采集', '收口版资料采集'] }
]

const rows = reactive([
  { no: '十五', category: '总平面工程量', name: '', unit: '', value: '', remark: '', readonly: true, group: true },
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
const currentTab = ref('项目收口')

const filteredRows = computed(() => {
  const keyword = query.value.trim().toLowerCase()
  if (!keyword) return rows
  return rows.filter((row) => Object.values(row).some((value) => String(value).toLowerCase().includes(keyword)))
})

const completion = computed(() => {
  const editable = rows.filter((row) => !row.group)
  const filled = editable.filter((row) => String(row.value).trim()).length
  return Math.round((filled / editable.length) * 100)
})
</script>

<template>
  <div class="app-shell">
    <aside class="sidebar">
      <div class="brand-card">
        <div class="brand-mark">EQ</div>
        <div>
          <strong>工程提资</strong>
          <span>Engineering Quantity</span>
        </div>
      </div>
      <nav class="menu-list">
        <section v-for="section in sections" :key="section.title" class="menu-section" :class="{ active: section.active }">
          <div class="section-title"><span>{{ section.icon }}</span>{{ section.title }}<b>⌃</b></div>
          <button v-for="item in section.items" :key="item" :class="{ selected: section.active && item === currentTab }" @click="currentTab = item">
            {{ item }}
          </button>
        </section>
      </nav>
    </aside>

    <main class="workspace">
      <header class="hero-bar">
        <div>
          <p>项目中心 / 基建初设</p>
          <h1>工程提资系统</h1>
        </div>
        <div class="hero-actions">
          <button>消息</button><button>个人中心</button><button class="primary">保存草稿</button>
        </div>
      </header>

      <div class="tabs"><button>个人中心</button><button>评审资料采集 ×</button><button class="active">{{ currentTab }} ×</button></div>

      <section class="content-card">
        <div class="toolbar">
          <div class="button-group"><button>↓ 数据导入</button><button>↑ 数据导出</button><button>▣ 打包下载</button></div>
          <div class="filters"><select><option>请选择项目类别</option></select><input v-model="query" placeholder="WBS编码、项目名称、子项" /><button class="primary">筛选</button><button>更多</button></div>
        </div>

        <div class="summary-strip">
          <div><span>当前模块</span><strong>{{ currentTab }}</strong></div>
          <div><span>待填写字段</span><strong>E列工程量</strong></div>
          <div><span>填写完成度</span><strong>{{ completion }}%</strong></div>
        </div>

        <div class="table-wrap">
          <table>
            <thead><tr><th>序号</th><th>项目名称</th><th>工程内容</th><th>单位</th><th class="editable-head">E列：用户填写</th><th>说明 / 备注</th><th>操作</th></tr></thead>
            <tbody>
              <tr v-for="row in filteredRows" :key="row.no" :class="{ group: row.group }">
                <td>{{ row.no }}</td><td>{{ row.category }}</td><td>{{ row.name || '—' }}</td><td>{{ row.unit }}</td>
                <td><input v-if="!row.group" v-model="row.value" class="quantity-input" /><span v-else>—</span></td>
                <td>{{ row.remark }}</td><td><button class="ghost">查看</button></td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </main>
  </div>
</template>

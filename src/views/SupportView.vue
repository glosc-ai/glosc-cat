<script setup lang="ts">
import { RouterLink } from 'vue-router'
</script>

<template>
  <div class="min-h-screen bg-[var(--color-cream-white)] py-12 px-6 sm:px-12 lg:px-24">
    <div class="max-w-3xl mx-auto bg-white rounded-[2rem] p-8 sm:p-12 shadow-[var(--shadow-soft)]">
      <div class="mb-8 flex items-center justify-between gap-4">
        <RouterLink
          to="/"
          class="flex items-center gap-2 text-[var(--color-sage-green)] hover:text-[var(--color-text-main)] transition-colors"
        >
          <span class="text-xl">←</span>
          <span class="font-medium">返回首页</span>
        </RouterLink>
        <div class="text-[var(--color-text-muted)] text-sm">更新日期：2026年3月21日</div>
      </div>

      <h1 class="font-cute text-4xl text-center mb-10 text-[var(--color-text-main)]">
        说猫语 - 技术支持
      </h1>

      <div class="prose prose-slate max-w-none text-[var(--color-text-main)] leading-loose">
        <section class="mb-8">
          <h2 class="font-cute text-2xl mb-4 text-[var(--color-peach-pink)]">1. 支持范围 🛠️</h2>
          <p>
            如果您在使用“说猫语”时遇到下载、安装、录音权限、音频导入、结果展示或播放异常等问题，可以通过本页面获取技术支持联系方式。
          </p>
        </section>

        <section class="mb-8">
          <h2 class="font-cute text-2xl mb-4 text-[var(--color-peach-pink)]">2. 常见问题建议 💡</h2>
          <ul class="list-disc pl-6 mt-2 space-y-2">
            <li>如无法录音，请先检查系统是否已授予麦克风权限。</li>
            <li>如导入音频失败，请尝试更换为常见音频格式后重新导入。</li>
            <li>如播放没有声音，请确认设备音量、静音设置及蓝牙音频输出状态。</li>
            <li>如页面显示异常，建议关闭应用后重新打开，或升级到最新版本。</li>
          </ul>
        </section>

        <section class="mb-8">
          <h2 class="font-cute text-2xl mb-4 text-[var(--color-peach-pink)]">3. 联系技术支持 📮</h2>
          <p>
            若以上方法仍未解决您的问题，请将问题现象、设备型号、系统版本以及相关截图发送给我们，我们会尽快协助处理。
          </p>
          <p class="mt-2">
            技术支持邮箱：
            <a href="mailto:xm@aoe.top" class="text-[var(--color-sage-green)] hover:underline">xm@aoe.top</a>
          </p>
        </section>

        <section>
          <h2 class="font-cute text-2xl mb-4 text-[var(--color-peach-pink)]">4. 支持时间 ⏰</h2>
          <p>
            我们会在收到邮件后尽快回复。节假日或高峰时段回复可能略有延迟，感谢您的理解与耐心等待。
          </p>
        </section>
      </div>

      <div class="mt-16 pt-8 border-t border-[var(--color-oat-apricot)] text-center text-[var(--color-text-muted)] text-sm">
        <p>© 2026 Glosc AI. 保留所有权利。</p>
      </div>
    </div>
  </div>
</template>

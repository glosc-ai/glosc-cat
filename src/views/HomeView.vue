<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { RouterLink } from 'vue-router'

const isScrolled = ref(false)
const isMenuOpen = ref(false)

const handleScroll = () => {
  isScrolled.value = window.scrollY > 20
}

onMounted(() => {
  window.addEventListener('scroll', handleScroll)
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
})

const toggleMenu = () => {
  isMenuOpen.value = !isMenuOpen.value
}
</script>

<template>
  <div class="min-h-screen bg-[var(--color-cream-white)] text-[var(--color-text-main)] overflow-x-hidden font-body">
    <!-- Navbar -->
    <nav :class="['fixed w-full z-50 transition-all duration-300 backdrop-blur-md', isScrolled ? 'bg-white/80 shadow-sm py-4' : 'bg-transparent py-6']">
      <div class="max-w-7xl mx-auto px-6 lg:px-12 flex justify-between items-center">
        <a href="#" class="flex items-center gap-3">
          <img src="/icon.png" alt="说猫语图标" class="w-10 h-10 rounded-full shadow-[var(--shadow-soft)] object-cover" />
          <span class="font-cute text-2xl tracking-wide text-[var(--color-text-main)]">说猫语</span>
        </a>

        <!-- Desktop Menu -->
        <div class="hidden md:flex items-center gap-8">
          <a href="#features" class="font-medium text-[var(--color-text-muted)] hover:text-[var(--color-peach-pink)]">功能介绍</a>
          <a href="#how-it-works" class="font-medium text-[var(--color-text-muted)] hover:text-[var(--color-peach-pink)]">如何使用</a>
          <RouterLink to="/privacy" class="font-medium text-[var(--color-text-muted)] hover:text-[var(--color-peach-pink)]">隐私政策</RouterLink>
          <a href="#download" class="bg-[var(--color-text-main)] hover:bg-[var(--color-peach-pink)] text-white px-6 py-2.5 rounded-full font-medium transition-colors shadow-md">
            立即下载
          </a>
        </div>

        <!-- Mobile Hamburger -->
        <button class="md:hidden text-2xl text-[var(--color-text-main)]" @click="toggleMenu">
          {{ isMenuOpen ? '✖' : '☰' }}
        </button>
      </div>

      <!-- Mobile Menu -->
      <div v-show="isMenuOpen" class="md:hidden absolute top-full left-0 w-full bg-white/95 backdrop-blur-md shadow-lg py-4 px-6 flex flex-col gap-4">
        <a href="#features" class="font-medium py-2 text-[var(--color-text-muted)]" @click="toggleMenu">功能介绍</a>
        <a href="#how-it-works" class="font-medium py-2 text-[var(--color-text-muted)]" @click="toggleMenu">如何使用</a>
        <RouterLink to="/privacy" class="font-medium py-2 text-[var(--color-text-muted)]" @click="toggleMenu">隐私政策</RouterLink>
        <a href="#download" class="bg-[var(--color-text-main)] text-white text-center px-6 py-3 rounded-2xl font-medium mt-2" @click="toggleMenu">
          立即下载
        </a>
      </div>
    </nav>

    <!-- Hero Section -->
    <section class="pt-32 pb-20 lg:pt-48 lg:pb-32 px-6 relative overflow-hidden">
      <!-- Decorative Elements -->
      <div class="absolute top-20 left-10 text-4xl opacity-20 animate-float-delayed rotate-[-20deg]">🐾</div>
      <div class="absolute top-40 right-10 text-6xl opacity-20 animate-float rotate-[15deg] text-[var(--color-peach-pink)]">💕</div>
      <div class="absolute bottom-20 left-1/4 text-5xl opacity-20 animate-float-reverse">🎵</div>
      <div class="absolute top-1/4 right-1/4 text-3xl opacity-20 animate-float-delayed">🐟</div>
      <div class="absolute -top-40 -right-40 w-96 h-96 bg-[var(--color-peach-pink)] rounded-full blur-[100px] opacity-20"></div>
      <div class="absolute -bottom-40 -left-40 w-96 h-96 bg-[var(--color-sage-green)] rounded-full blur-[100px] opacity-20"></div>

      <div class="max-w-4xl mx-auto text-center relative z-10">
        <div class="inline-block mb-6 px-4 py-1.5 rounded-full bg-[var(--color-oat-apricot)]/50 text-[var(--color-text-main)] text-sm font-medium border border-[var(--color-oat-apricot)]">
          ✨ 懂它的每一次喵喵叫
        </div>
        <h1 class="font-cute text-5xl md:text-7xl mb-8 leading-tight text-[var(--color-text-main)]">
          听懂你的猫咪<br class="md:hidden" />在说什么
        </h1>
        <p class="text-lg md:text-xl text-[var(--color-text-muted)] mb-12 max-w-2xl mx-auto leading-relaxed">
          把“听不懂它在说什么”变成简单、轻松、可爱的日常互动。分析情绪、理解需求，用更贴近它的方式回应爱。
        </p>
        
        <div class="flex flex-col sm:flex-row items-center justify-center gap-6">
          <a href="#download" class="w-full sm:w-auto flex items-center justify-center gap-3 bg-[var(--color-text-main)] hover:bg-[var(--color-peach-pink)] text-white px-8 py-4 rounded-full text-lg font-medium transition-all shadow-lg hover:shadow-[var(--shadow-float)] hover:-translate-y-1">
            <span>🍎</span> App Store 下载
          </a>
          <a href="#features" class="w-full sm:w-auto flex items-center justify-center gap-2 text-[var(--color-text-main)] px-8 py-4 rounded-full text-lg font-medium border-2 border-[var(--color-oat-apricot)] hover:bg-[var(--color-oat-apricot)]/30 transition-all">
            了解更多 <span class="text-xl">↓</span>
          </a>
        </div>
      </div>
    </section>

    <!-- Features Section -->
    <section id="features" class="py-24 px-6 bg-white/50 relative">
      <div class="max-w-7xl mx-auto">
        <div class="text-center mb-16">
          <h2 class="font-cute text-4xl mb-4">三个动作，拉近彼此距离</h2>
          <p class="text-[var(--color-text-muted)]">让每一次沟通都充满陪伴感</p>
        </div>

        <div class="grid md:grid-cols-3 gap-8">
          <!-- Feature 1 -->
          <div class="bg-white rounded-[2rem] p-8 shadow-[var(--shadow-soft)] hover:shadow-xl transition-all duration-300 hover:-translate-y-2 group">
            <div class="w-16 h-16 bg-[var(--color-peach-pink)]/20 rounded-2xl flex items-center justify-center text-3xl mb-6 group-hover:scale-110 transition-transform">
              🎙️
            </div>
            <h3 class="font-cute text-2xl mb-4">猫语转人话</h3>
            <p class="text-[var(--color-text-muted)] leading-relaxed">
              录制猫咪叫声，智能分析音色、频率、节奏和时长。不仅告诉你它在说什么，还提供通俗的解释和照护建议。
            </p>
          </div>

          <!-- Feature 2 -->
          <div class="bg-white rounded-[2rem] p-8 shadow-[var(--shadow-soft)] hover:shadow-xl transition-all duration-300 hover:-translate-y-2 group">
            <div class="w-16 h-16 bg-[var(--color-sage-green)]/20 rounded-2xl flex items-center justify-center text-3xl mb-6 group-hover:scale-110 transition-transform">
              💬
            </div>
            <h3 class="font-cute text-2xl mb-4">人话转猫语</h3>
            <p class="text-[var(--color-text-muted)] leading-relaxed">
              输入想对它说的话，选择温柔、安抚或召唤等语气。系统会自动匹配最贴近的真实猫叫音频并播放，互动更有趣。
            </p>
          </div>

          <!-- Feature 3 -->
          <div class="bg-white rounded-[2rem] p-8 shadow-[var(--shadow-soft)] hover:shadow-xl transition-all duration-300 hover:-translate-y-2 group">
            <div class="w-16 h-16 bg-[var(--color-light-brown)]/20 rounded-2xl flex items-center justify-center text-3xl mb-6 group-hover:scale-110 transition-transform">
              💖
            </div>
            <h3 class="font-cute text-2xl mb-4">情绪与需求分析</h3>
            <p class="text-[var(--color-text-muted)] leading-relaxed">
              精准识别快乐、紧张、饥饿、求关注等常见情绪与需求信号。拒绝冷冰冰的机器判断，给您一份有温度的解读。
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- How It Works Section -->
    <section id="how-it-works" class="py-24 px-6 relative overflow-hidden">
      <div class="absolute top-0 right-0 w-[800px] h-[800px] bg-[var(--color-oat-apricot)] rounded-full blur-[120px] opacity-30 -z-10"></div>
      
      <div class="max-w-7xl mx-auto">
        <div class="text-center mb-16">
          <h2 class="font-cute text-4xl mb-4">怎么使用？</h2>
          <p class="text-[var(--color-text-muted)]">三步开启你们的专属对话频道</p>
        </div>

        <div class="flex flex-col md:flex-row items-center justify-center gap-12 lg:gap-24 relative">
          <!-- Connection line (desktop) -->
          <div class="hidden md:block absolute top-12 left-1/4 right-1/4 h-0.5 bg-gradient-to-r from-[var(--color-peach-pink)] to-[var(--color-sage-green)] opacity-30 z-0"></div>

          <!-- Step 1 -->
          <div class="flex flex-col items-center text-center relative z-10 w-full md:w-1/3">
            <div class="w-24 h-24 bg-white rounded-full flex items-center justify-center text-4xl shadow-lg mb-6 border-4 border-[var(--color-cream-white)]">
              📱
            </div>
            <h3 class="font-cute text-xl mb-3">1. 录音或输入</h3>
            <p class="text-[var(--color-text-muted)]">点击录音按钮收集它的叫声，或者直接打字输入你想说的话。</p>
          </div>

          <!-- Step 2 -->
          <div class="flex flex-col items-center text-center relative z-10 w-full md:w-1/3">
            <div class="w-24 h-24 bg-[var(--color-peach-pink)] rounded-full flex items-center justify-center text-4xl text-white shadow-lg mb-6 border-4 border-[var(--color-cream-white)] animate-pulse">
              ✨
            </div>
            <h3 class="font-cute text-xl mb-3">2. 智能分析</h3>
            <p class="text-[var(--color-text-muted)]">本地化安全处理，匹配真实猫叫样本库，快速提取情绪特征。</p>
          </div>

          <!-- Step 3 -->
          <div class="flex flex-col items-center text-center relative z-10 w-full md:w-1/3">
            <div class="w-24 h-24 bg-white rounded-full flex items-center justify-center text-4xl shadow-lg mb-6 border-4 border-[var(--color-cream-white)]">
              🎁
            </div>
            <h3 class="font-cute text-xl mb-3">3. 获取结果</h3>
            <p class="text-[var(--color-text-muted)]">查看可爱易读的结果卡片，播放猫语，或者参考照护建议。</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Highlights Section -->
    <section class="py-24 px-6 bg-[var(--color-text-main)] text-white relative overflow-hidden">
      <!-- Decorative background pattern -->
      <div class="absolute inset-0 opacity-5" style="background-image: radial-gradient(var(--color-cream-white) 2px, transparent 2px); background-size: 30px 30px;"></div>
      
      <div class="max-w-7xl mx-auto relative z-10">
        <div class="grid md:grid-cols-2 gap-16 items-center">
          <div>
            <h2 class="font-cute text-4xl md:text-5xl mb-8 leading-tight text-[var(--color-cream-white)]">
              为什么选择<br />说猫语？
            </h2>
            <p class="text-[var(--color-oat-apricot)] text-lg mb-10 opacity-90">
              我们不是冷冰冰的机器翻译，而是致力于打造有温度、有陪伴感的养宠日常。
            </p>

            <div class="space-y-6">
              <div class="flex items-start gap-4">
                <div class="w-10 h-10 rounded-full bg-[var(--color-peach-pink)]/20 flex items-center justify-center shrink-0 mt-1">
                  🎨
                </div>
                <div>
                  <h4 class="font-cute text-xl text-[var(--color-peach-pink)] mb-1">治愈系软糯 UI</h4>
                  <p class="text-white/70 text-sm">奶油白与蜜桃粉的温柔碰撞，为“养宠女孩”量身定制的审美体验。</p>
                </div>
              </div>
              
              <div class="flex items-start gap-4">
                <div class="w-10 h-10 rounded-full bg-[var(--color-sage-green)]/20 flex items-center justify-center shrink-0 mt-1">
                  🛡️
                </div>
                <div>
                  <h4 class="font-cute text-xl text-[var(--color-sage-green)] mb-1">本地处理，隐私无忧</h4>
                  <p class="text-white/70 text-sm">所有音频特征分析与对比均在本地完成，绝不上传您的私人录音。</p>
                </div>
              </div>

              <div class="flex items-start gap-4">
                <div class="w-10 h-10 rounded-full bg-[var(--color-oat-apricot)]/20 flex items-center justify-center shrink-0 mt-1">
                  🐈
                </div>
                <div>
                  <h4 class="font-cute text-xl text-[var(--color-oat-apricot)] mb-1">真实猫叫样本库</h4>
                  <p class="text-white/70 text-sm">基于海量真实音频样本比对，告别粗糙的合成电子音。</p>
                </div>
              </div>
            </div>
          </div>

          <!-- App preview -->
          <div class="relative flex justify-center">
            <div class="w-[300px] max-w-full bg-[var(--color-cream-white)] rounded-[3rem] p-3 relative shadow-2xl border border-white/40 rotate-2 hover:rotate-0 transition-transform duration-500">
              <img
                src="/Home.png"
                alt="说猫语应用界面预览"
                class="block w-full h-auto rounded-[2.4rem] shadow-inner"
              />
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Download CTA -->
    <section id="download" class="py-32 px-6 relative overflow-hidden">
      <div class="absolute inset-0 bg-gradient-soft opacity-50"></div>
      
      <div class="max-w-4xl mx-auto text-center relative z-10 bg-white/60 backdrop-blur-xl p-12 md:p-20 rounded-[3rem] shadow-[var(--shadow-soft)] border border-white">
        <div class="text-5xl mb-6">🐾</div>
        <h2 class="font-cute text-4xl md:text-5xl mb-6 text-[var(--color-text-main)]">
          立即下载，开始和猫咪对话
        </h2>
        <p class="text-[var(--color-text-muted)] mb-10 text-lg">
          加入众多铲屎官的行列，每天多懂它一点点。
        </p>
        
        <a href="#" class="inline-flex items-center justify-center gap-3 bg-[var(--color-text-main)] hover:bg-[var(--color-peach-pink)] text-white px-10 py-5 rounded-full text-xl font-medium transition-all shadow-lg hover:shadow-[var(--shadow-float)] hover:-translate-y-1">
          <span>🍎</span> 前往 App Store 下载
        </a>
      </div>
    </section>

    <!-- Footer -->
    <footer class="bg-white pt-16 pb-8 px-6 border-t border-[var(--color-cream-white)]">
      <div class="max-w-7xl mx-auto flex flex-col items-center text-center">
        <div class="flex items-center gap-2 mb-6 text-[var(--color-text-main)] opacity-80">
          <img src="/icon.png" alt="说猫语图标" class="w-8 h-8 rounded-full object-cover" />
          <span class="font-cute text-xl">说猫语</span>
        </div>
        
        <p class="text-[var(--color-text-muted)] mb-8 max-w-sm text-sm">
          把“听不懂它在说什么”变成简单、轻松、可爱的日常互动。
        </p>

        <div class="flex gap-6 mb-12">
          <RouterLink to="/privacy" class="text-[var(--color-text-muted)] hover:text-[var(--color-peach-pink)] text-sm transition-colors">隐私政策</RouterLink>
          <a href="mailto:xm@aoe.top" class="text-[var(--color-text-muted)] hover:text-[var(--color-peach-pink)] text-sm transition-colors">联系我们</a>
        </div>

        <div class="w-full h-px bg-[var(--color-cream-white)] mb-8"></div>
        
        <p class="text-[var(--color-text-muted)]/60 text-xs">
          © 2026 Glosc AI. 保留所有权利。
        </p>
        <p class="text-[var(--color-text-muted)]/60 text-xs mt-1">
          <a href="https://beian.miit.gov.cn/" target="_blank" rel="noopener noreferrer" class="hover:text-[var(--color-text-muted)] transition-colors">沪ICP备2026003781号-1</a>
        </p>
        <p class="text-[var(--color-text-muted)]/60 text-xs mt-1">
          <a href="https://www.beian.gov.cn/portal/registerSystemInfo?recordcode=31011202022083" target="_blank" rel="noopener noreferrer" class="hover:text-[var(--color-text-muted)] transition-colors">沪公网安备31011202022083号</a>
        </p>
      </div>
    </footer>
  </div>
</template>

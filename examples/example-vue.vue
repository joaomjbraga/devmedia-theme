<!-- Vue.js 3 - Composition API -->
<template>
  <div class="course-list">
    <h1>Cursos DevMedia</h1>
    
    <input
      v-model="searchQuery"
      type="text"
      placeholder="Buscar cursos..."
    />
    
    <div v-if="loading" class="loading">Carregando...</div>
    
    <div v-else class="courses">
      <div
        v-for="course in filteredCourses"
        :key="course.id"
        class="course-card"
      >
        <h3>{{ course.title }}</h3>
        <p>{{ course.description }}</p>
        <span class="price">R$ {{ course.price.toFixed(2) }}</span>
        <button @click="enroll(course.id)">Matricular</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';

interface Course {
  id: number;
  title: string;
  description: string;
  price: number;
  instructor: string;
}

const courses = ref<Course[]>([]);
const searchQuery = ref('');
const loading = ref(false);

const filteredCourses = computed(() => {
  if (!searchQuery.value) return courses.value;
  
  return courses.value.filter(course =>
    course.title.toLowerCase().includes(searchQuery.value.toLowerCase())
  );
});

const loadCourses = async () => {
  loading.value = true;
  
  // Mock data
  courses.value = [
    { id: 1, title: 'Vue.js 3', description: 'Aprenda Vue', price: 299.90, instructor: 'João' },
    { id: 2, title: 'TypeScript', description: 'TS completo', price: 399.90, instructor: 'Maria' },
  ];
  
  loading.value = false;
};

const enroll = (courseId: number) => {
  console.log('Enrolling:', courseId);
};

onMounted(() => {
  loadCourses();
});
</script>

<style scoped>
.course-list {
  padding: 20px;
}

.courses {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.course-card {
  border: 2px solid #6F9A35;
  padding: 20px;
  border-radius: 8px;
}

.price {
  color: #6F9A35;
  font-size: 24px;
  font-weight: bold;
}
</style>

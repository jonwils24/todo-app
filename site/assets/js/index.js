// Release v0.0.4

const { createApp } = Vue

// Set constants for API calls
const api_url = "	https://dtgwwj1opa.execute-api.us-east-1.amazonaws.com/default/todos"
const api_headers = { "Content-Type": "application/json" }

createApp({
  data() {
    return {
      newTodoInput: '',
      todos: []
    }
  },
  async created() {
    const response = await fetch(api_url)
    this.todos = await response.json();
  },
  methods: {
    async addTodo() {
      if (this.newTodoInput === "") {
        return;
      }
      let todoId = new Date().getTime();
      await fetch(api_url + "/" + todoId, {
        method: "post",
        headers: api_headers,
        body: JSON.stringify({ name: this.newTodoInput })
      })
      this.todos.push({ id: todoId, name: this.newTodoInput })
      this.newTodoInput = ''
    },
    async removeTodo(todoId) {
      this.todos = this.todos.filter((t) => t.id !== todoId)
      await fetch(api_url + "/" + todoId, {
        method: "delete",
        headers: api_headers
      })
    },
    async updateTodo(todoId) {
      this.todo = this.todos.filter((t) => t.id === todoId)
      let current_status = this.todo.status
      this.todo.status = current_status === "complete" ? "open" : "complete"
      await fetch(api_url + "/" + todoId, {
        method: "put",
        headers: api_headers,
        body: JSON.stringify({ status: this.todo.status })
      })
    }
  }
}).mount('#app')
